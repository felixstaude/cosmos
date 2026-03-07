#!/bin/bash
# ================================================================
# COSMOS — Multi-Agent Daily Pipeline v4
# Refactored: agents defined in agents/*.md, parallel coders,
# ISSUE_RESOLVER gate, weekly SELF_IMPROVER cycle.
# ================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
DATE=$(date +%Y-%m-%d)
DAY_OF_WEEK=$(date +%u)  # 1=Monday, 7=Sunday
SESSION_DIR="logs/${TIMESTAMP}"
LOGFILE="${SESSION_DIR}/pipeline.log"
REPO_OWNER="felixstaude"

mkdir -p "$SESSION_DIR" tmp

log()       { echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOGFILE"; }
separator() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOGFILE"; }

separator
log "COSMOS Daily Pipeline v4 — $TIMESTAMP"
separator

cp index.html "${SESSION_DIR}/index.backup.html"
log "Backup saved"

# ── Label non-owner issues ────────────────────────────────────────
log "Checking issues..."
gh issue list --state open --json number,author,labels --limit 50 2>/dev/null | \
python3 -c "
import json, sys
issues = json.load(sys.stdin)
for issue in issues:
    author = issue['author']['login']
    labels = [l['name'] for l in issue['labels']]
    num = issue['number']
    if author != 'felixstaude' and 'approved' not in labels and 'needs-approval' not in labels:
        print('LABEL:' + str(num))
" 2>/dev/null | while IFS=: read -r action num; do
    [ "$action" = "LABEL" ] && gh issue edit "$num" --add-label "needs-approval" 2>/dev/null || true
    log "  Issue #$num labeled needs-approval"
done
log "Issue check done"

# ── Find work target ──────────────────────────────────────────────
log "Finding work target..."
ISSUE_NUM=""
ISSUE_TITLE=""
BRANCH_NAME=""

SELECTED=$(gh issue list --state open --limit 20 --json number,title,author,labels 2>/dev/null | \
python3 -c "
import json, sys
issues = json.load(sys.stdin)
for issue in sorted(issues, key=lambda x: x['number']):
    author = issue['author']['login']
    labels = [l['name'] for l in issue['labels']]
    if (author == 'felixstaude' or 'approved' in labels) and 'in-progress' not in labels:
        print(str(issue['number']) + '|' + issue['title'])
        break
" 2>/dev/null || echo "")

if [ -n "$SELECTED" ]; then
    ISSUE_NUM=$(echo "$SELECTED" | cut -d'|' -f1)
    ISSUE_TITLE=$(echo "$SELECTED" | cut -d'|' -f2-)
    BRANCH_NAME="issue-${ISSUE_NUM}-$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-40)"
    log "Issue #${ISSUE_NUM}: ${ISSUE_TITLE}"
    gh issue edit "$ISSUE_NUM" --add-label "in-progress" 2>/dev/null || true
    git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME" 2>/dev/null
    log "Branch: $BRANCH_NAME"
else
    log "  No eligible issues — agent self-decides"
fi

# ── Agent runner ──────────────────────────────────────────────────
run_agent() {
    local NAME="$1"
    local AGENT_FILE="$2"
    local EXTRA_CONTEXT="$3"
    local OUTFILE="${SESSION_DIR}/${NAME,,}.md"
    log ""
    log "Agent: $NAME"
    local START=$(date +%s)
    echo "Read agents/${AGENT_FILE} and follow it exactly.

Session dir: ${SESSION_DIR}
Retry: ${RETRY:-0}
${EXTRA_CONTEXT}" | claude --print --dangerously-skip-permissions 2>>"$LOGFILE" | tee "$OUTFILE" >> "$LOGFILE"
    local DURATION=$(( $(date +%s) - START ))
    log "$NAME done (${DURATION}s)"
}

# Run an agent and write output to a specific file
run_agent_to() {
    local NAME="$1"
    local AGENT_FILE="$2"
    local OUTFILE="$3"
    local EXTRA_CONTEXT="$4"
    log ""
    log "Agent: $NAME"
    local START=$(date +%s)
    echo "Read agents/${AGENT_FILE} and follow it exactly.

Session dir: ${SESSION_DIR}
Retry: ${RETRY:-0}
${EXTRA_CONTEXT}" | claude --print --dangerously-skip-permissions 2>>"$LOGFILE" | tee "$OUTFILE" >> "$LOGFILE"
    local DURATION=$(( $(date +%s) - START ))
    log "$NAME done (${DURATION}s)"
}

check_pass() {
    local FILE="$1"
    grep -qi "FINAL.*PASS" "$FILE" 2>/dev/null && ! grep -qi "FINAL.*FAIL" "$FILE" 2>/dev/null
}

check_status_pass() {
    local FILE="$1"
    grep -qi "STATUS.*PASS" "$FILE" 2>/dev/null && ! grep -qi "STATUS.*FAIL" "$FILE" 2>/dev/null
}

# ── PLANNER ───────────────────────────────────────────────────────
if [ -n "$ISSUE_NUM" ]; then
    WORK_CONTEXT="Work on Issue #${ISSUE_NUM}: '${ISSUE_TITLE}'. Focus entirely on this."
else
    WORK_CONTEXT="No open issues. Decide yourself. Priority: new planets > shader improvements > UI features > bugfixes."
fi

run_agent_to "PLANNER" "PLANNER.md" "${SESSION_DIR}/plan.md" "$WORK_CONTEXT"

# ── ARCHITECT ─────────────────────────────────────────────────────
run_agent_to "ARCHITECT" "ARCHITECT.md" "${SESSION_DIR}/implementation.md" ""

# ── PIPELINE LOOP ─────────────────────────────────────────────────
RETRY=0

while true; do

    separator
    [ $RETRY -gt 0 ] && log "Retry #${RETRY} — applying fixes only" || log "Attempt 1"
    separator

    FIX_CONTEXT=""
    if [ -f "${SESSION_DIR}/fix_retry${RETRY}.md" ]; then
        FIX_CONTENT=$(cat "${SESSION_DIR}/fix_retry${RETRY}.md")
        FIX_CONTEXT="
CRITICAL — Previous attempt failed. Apply ALL these fixes first, do NOT rewrite whole files:

${FIX_CONTENT}"
    fi

    # ── Parallel CODERS ──────────────────────────────────────────
    log "Running parallel coders..."

    run_agent_to "CODER_SHADER" "CODER_SHADER.md" \
        "${SESSION_DIR}/coder_shader_retry${RETRY}.md" "$FIX_CONTEXT" &
    PID_SHADER=$!

    run_agent_to "CODER_LOGIC" "CODER_LOGIC.md" \
        "${SESSION_DIR}/coder_logic_retry${RETRY}.md" "$FIX_CONTEXT" &
    PID_LOGIC=$!

    run_agent_to "CODER_UI" "CODER_UI.md" \
        "${SESSION_DIR}/coder_ui_retry${RETRY}.md" "$FIX_CONTEXT" &
    PID_UI=$!

    # Wait for all parallel coders
    wait $PID_SHADER $PID_LOGIC $PID_UI
    log "All coders complete"

    # ── INTEGRATOR ───────────────────────────────────────────────
    run_agent_to "INTEGRATOR" "INTEGRATOR.md" \
        "${SESSION_DIR}/integrator_retry${RETRY}.md" ""

    # ── Parallel checks: TESTER, SECURITY, REVIEWER ──────────────
    log "Running parallel checks..."

    run_agent_to "TESTER" "TESTER.md" \
        "${SESSION_DIR}/test_retry${RETRY}.md" "" &
    PID_TEST=$!

    run_agent_to "SECURITY" "SECURITY.md" \
        "${SESSION_DIR}/security_retry${RETRY}.md" "" &
    PID_SEC=$!

    run_agent_to "REVIEWER" "REVIEWER.md" \
        "${SESSION_DIR}/review_retry${RETRY}.md" "" &
    PID_REV=$!

    wait $PID_TEST $PID_SEC $PID_REV
    log "All checks complete"

    # ── VALIDATOR ────────────────────────────────────────────────
    run_agent_to "VALIDATOR" "VALIDATOR.md" \
        "${SESSION_DIR}/validation_retry${RETRY}.md" ""

    VAL_FILE="${SESSION_DIR}/validation_retry${RETRY}.md"

    if check_pass "$VAL_FILE"; then
        log ""
        log "All checks PASSED after $RETRY retries!"
        break
    else
        FAILED=$(grep -i "FAILED_CHECKS:" "$VAL_FILE" 2>/dev/null | sed 's/.*FAILED_CHECKS: *//' || echo "unknown")
        RETRY=$((RETRY + 1))
        log "Validation FAILED — retry #${RETRY} (failed: $FAILED)"

        if [ $RETRY -ge 4 ]; then
            log "Max retries reached. Proceeding with best effort."
            break
        fi
    fi

done

# ── ISSUE_RESOLVER (only if working on an issue) ─────────────────
if [ -n "$ISSUE_NUM" ]; then
    separator
    log "Running ISSUE_RESOLVER for issue #${ISSUE_NUM}..."

    ISSUE_BODY=$(gh issue view "$ISSUE_NUM" --json body -q '.body' 2>/dev/null || echo "Could not fetch issue body")

    run_agent_to "ISSUE_RESOLVER" "ISSUE_RESOLVER.md" \
        "${SESSION_DIR}/issue_resolution.md" \
        "Issue number: ${ISSUE_NUM}
Issue title: ${ISSUE_TITLE}
Issue body:
${ISSUE_BODY}"

    IR_FILE="${SESSION_DIR}/issue_resolution.md"

    if ! check_status_pass "$IR_FILE"; then
        log "ISSUE_RESOLVER FAILED — requirements not fully met"
        MISSING=$(grep -A 100 "MISSING_ITEMS:" "$IR_FILE" 2>/dev/null | tail -n +2 || echo "unknown gaps")
        log "Missing: $MISSING"

        # Feed back into retry loop with specific instructions
        if [ $RETRY -lt 4 ]; then
            RETRY=$((RETRY + 1))
            cat > "${SESSION_DIR}/fix_retry${RETRY}.md" << FIXEOF
ISSUE_RESOLVER found missing requirements. Fix these BEFORE anything else:

${MISSING}

Original issue: #${ISSUE_NUM} — ${ISSUE_TITLE}
FIXEOF
            log "Re-entering pipeline loop for issue resolution..."

            # Re-run coders -> integrator -> checks -> validator
            FIX_CONTENT=$(cat "${SESSION_DIR}/fix_retry${RETRY}.md")
            FIX_CONTEXT="
CRITICAL — ISSUE_RESOLVER found missing requirements:

${FIX_CONTENT}"

            run_agent_to "CODER_SHADER" "CODER_SHADER.md" \
                "${SESSION_DIR}/coder_shader_retry${RETRY}.md" "$FIX_CONTEXT" &
            run_agent_to "CODER_LOGIC" "CODER_LOGIC.md" \
                "${SESSION_DIR}/coder_logic_retry${RETRY}.md" "$FIX_CONTEXT" &
            run_agent_to "CODER_UI" "CODER_UI.md" \
                "${SESSION_DIR}/coder_ui_retry${RETRY}.md" "$FIX_CONTEXT" &
            wait

            run_agent_to "INTEGRATOR" "INTEGRATOR.md" \
                "${SESSION_DIR}/integrator_retry${RETRY}.md" ""

            run_agent_to "VALIDATOR" "VALIDATOR.md" \
                "${SESSION_DIR}/validation_retry${RETRY}.md" ""

            # Re-run issue resolver
            run_agent_to "ISSUE_RESOLVER" "ISSUE_RESOLVER.md" \
                "${SESSION_DIR}/issue_resolution.md" \
                "Issue number: ${ISSUE_NUM}
Issue title: ${ISSUE_TITLE}
Issue body:
${ISSUE_BODY}"
        fi
    else
        log "ISSUE_RESOLVER: all requirements met"
    fi
fi

# ── COMMIT & PUSH ─────────────────────────────────────────────────
separator
log "Committing..."

VAL_FILE="${SESSION_DIR}/validation_retry${RETRY}.md"
SUMMARY=$(grep -i "^SUMMARY:" "$VAL_FILE" 2>/dev/null | sed 's/^SUMMARY: *//' || echo "Daily improvements")
PLAN_TASK=$(grep "^TASK:" "${SESSION_DIR}/plan.md" 2>/dev/null | sed 's/^TASK: *//' || echo "Daily update")
COMMIT_MSG="[COSMOS] $PLAN_TASK"
[ -n "$ISSUE_NUM" ] && COMMIT_MSG="[COSMOS] #${ISSUE_NUM} — $PLAN_TASK"

cat >> data/changelog.md << EOF

## $DATE — $TIMESTAMP
**Task:** $PLAN_TASK
**Result:** $SUMMARY
**Retries:** $RETRY
**Issue:** ${ISSUE_NUM:-none}
**Logs:** $SESSION_DIR
EOF

git add -A
git commit -m "$COMMIT_MSG"
log "Committed: $COMMIT_MSG"

if [ -n "$BRANCH_NAME" ]; then
    log "Merging $BRANCH_NAME -> main"
    git checkout main
    git merge "$BRANCH_NAME" --no-ff -m "Merge: $COMMIT_MSG"
    git branch -d "$BRANCH_NAME"
    log "Merged"
fi

git push origin main
log "Pushed"

if [ -n "$ISSUE_NUM" ]; then
    gh issue close "$ISSUE_NUM" --comment "Resolved in \`$COMMIT_MSG\` — $SUMMARY (retries: $RETRY)" 2>/dev/null || true
    gh issue edit "$ISSUE_NUM" --remove-label "in-progress" 2>/dev/null || true
    log "Issue #$ISSUE_NUM closed"
fi

# ── SELF_IMPROVER (runs on Sundays) ──────────────────────────────
if [ "$DAY_OF_WEEK" = "7" ]; then
    separator
    log "Running weekly SELF_IMPROVER..."
    run_agent_to "SELF_IMPROVER" "SELF_IMPROVER.md" \
        "${SESSION_DIR}/self_improvement.md" \
        "Today is Sunday. Run the weekly self-improvement cycle."

    # Check if self-improver made changes
    if git diff --quiet agents/; then
        log "SELF_IMPROVER: no changes made"
    else
        git add agents/
        git commit -m "[COSMOS] Self-improvement: weekly agent refinement"
        git push origin main
        log "SELF_IMPROVER: improvements committed and pushed"
    fi
fi

separator
log "Done! | Task: $PLAN_TASK | Retries: $RETRY | Logs: $SESSION_DIR"
separator
