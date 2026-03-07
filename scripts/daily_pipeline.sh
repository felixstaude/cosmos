#!/bin/bash
# ================================================================
# COSMOS — Multi-Agent Daily Pipeline v3
# ================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
DATE=$(date +%Y-%m-%d)
SESSION_DIR="logs/${TIMESTAMP}"
LOGFILE="${SESSION_DIR}/pipeline.log"
REPO_OWNER="felixstaude"

mkdir -p "$SESSION_DIR" tmp

log()       { echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOGFILE"; }
separator() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOGFILE"; }

separator
log "COSMOS Daily Pipeline v3 — $TIMESTAMP"
separator

cp index.html "${SESSION_DIR}/index.backup.html"
log "✓ Backup saved"

# ── Label non-owner issues ────────────────────────────────────────
log "🔍 Checking issues..."
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
    log "  ⚠ Issue #$num labeled needs-approval"
done
log "✓ Issue check done"

# ── Find work target ──────────────────────────────────────────────
log "🎯 Finding work target..."
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
    log "✓ Issue #${ISSUE_NUM}: ${ISSUE_TITLE}"
    gh issue edit "$ISSUE_NUM" --add-label "in-progress" 2>/dev/null || true
    git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME" 2>/dev/null
    log "✓ Branch: $BRANCH_NAME"
else
    log "  No eligible issues — agent self-decides"
fi

# ── Agent runner ──────────────────────────────────────────────────
run_agent() {
    local NAME="$1"
    local PROMPT="$2"
    local OUTFILE="${SESSION_DIR}/$3"
    log ""
    log "▶ Agent: $NAME"
    local START=$(date +%s)
    echo "$PROMPT" | claude --print --dangerously-skip-permissions 2>>"$LOGFILE" | tee "$OUTFILE" >> "$LOGFILE"
    local DURATION=$(( $(date +%s) - START ))
    log "✓ $NAME done (${DURATION}s)"
}

check_pass() {
    local FILE="$1"
    grep -qi "FINAL.*PASS" "$FILE" 2>/dev/null && ! grep -qi "FINAL.*FAIL" "$FILE" 2>/dev/null
}

# ── PLANNER ───────────────────────────────────────────────────────
if [ -n "$ISSUE_NUM" ]; then
    WORK_CONTEXT="Work on Issue #${ISSUE_NUM}: '${ISSUE_TITLE}'. Focus entirely on this."
else
    WORK_CONTEXT="No open issues. Decide yourself. Priority: new planets > shader improvements > UI features > bugfixes."
fi

run_agent "PLANNER" \
"You are the PLANNER agent for COSMOS — a procedural universe explorer (single-file web app).

${WORK_CONTEXT}

Read: CLAUDE.md, data/changelog.md, data/universe.json

Write ${SESSION_DIR}/plan.md using EXACTLY this format:

TASK: <one sentence>
TYPE: <issue|planet|shader|ui|feature|bugfix>
ISSUE_NUMBER: <number or none>
DETAILS:
- <detail 1>
- <detail 2>
EXPECTED_RESULT:
<what will be visibly different>" \
"plan.md"

# ── ARCHITECT ─────────────────────────────────────────────────────
run_agent "ARCHITECT" \
"You are the ARCHITECT for COSMOS.

Read: ${SESSION_DIR}/plan.md, src/main.js, src/planets.js, src/shaders.js, src/ui.js, src/style.css, CLAUDE.md

Write ${SESSION_DIR}/implementation.md:

LOCATION: <which file(s) in src/ to modify>
APPROACH: <technical approach>
CHANGES:
1. <specific change>
2. <specific change>
GLSL_NOTES: <shader notes or none>
VALIDATION_CRITERIA:
- <what tester should verify>" \
"implementation.md"

# ── PIPELINE LOOP ─────────────────────────────────────────────────
RETRY=0

while true; do

    separator
    [ $RETRY -gt 0 ] && log "🔄 Retry #${RETRY} — keeping current code, applying fixes only" || log "▶ Attempt 1"
    separator

    FIX_CONTEXT=""
    if [ -f "${SESSION_DIR}/fix_retry${RETRY}.md" ]; then
        FIX_CONTENT=$(cat "${SESSION_DIR}/fix_retry${RETRY}.md")
        FIX_CONTEXT="
CRITICAL — Previous attempt failed. Apply ALL these fixes first, do NOT rewrite the whole file:

${FIX_CONTENT}"
    fi

    run_agent "CODER" \
"You are the CODER for COSMOS.
Read: ${SESSION_DIR}/plan.md, ${SESSION_DIR}/implementation.md, CLAUDE.md, src/main.js, src/planets.js, src/shaders.js, src/ui.js, src/style.css
${FIX_CONTEXT}

Implement changes in the appropriate file(s) in src/.
Rules: allowed CDN: Three.js (installed via npm) + Google Fonts, never remove planets, no object allocation inside animation loop.

Write ${SESSION_DIR}/coder_retry${RETRY}.md: what you changed and why." \
"coder_retry${RETRY}.md"

    run_agent "TESTER" \
"You are the TESTER for COSMOS.
Read: ${SESSION_DIR}/plan.md, ${SESSION_DIR}/implementation.md, ${SESSION_DIR}/coder_retry${RETRY}.md, src/main.js, src/planets.js, src/shaders.js, src/ui.js, src/style.css

Verify: plan implemented, no JS syntax errors, valid GLSL, data structures correct, nothing broken.

Write ${SESSION_DIR}/test_retry${RETRY}.md:
STATUS: PASS
ISSUES:
- none
or
STATUS: FAIL
ISSUES:
- <specific issue with line numbers>
VERDICT: <one sentence>" \
"test_retry${RETRY}.md"

    run_agent "SECURITY" \
"You are the SECURITY agent for COSMOS.
Read src/main.js, src/planets.js, src/shaders.js, src/ui.js, src/style.css fully.
Check: no unauthorized external URLs (only Three.js via npm + Google Fonts allowed), no eval/innerHTML risks, no hardcoded secrets, no external fetch calls.

Write ${SESSION_DIR}/security_retry${RETRY}.md:
STATUS: PASS
ISSUES:
- none
or
STATUS: FAIL
ISSUES:
- <specific issue>
VERDICT: <one sentence>" \
"security_retry${RETRY}.md"

    run_agent "REVIEWER" \
"You are the CODE REVIEWER for COSMOS.
Read: ${SESSION_DIR}/coder_retry${RETRY}.md, src/main.js, src/planets.js, src/shaders.js, src/ui.js, src/style.css (changed sections)
Check: no object allocation in animation loop, efficient GLSL, consistent style, no dead code, no memory leaks.

Write ${SESSION_DIR}/review_retry${RETRY}.md:
STATUS: PASS
ISSUES:
- none
or
STATUS: FAIL
ISSUES:
- <specific issue with location>
VERDICT: <one sentence>" \
"review_retry${RETRY}.md"

    run_agent "VALIDATOR" \
"You are the VALIDATOR for COSMOS.
Read: ${SESSION_DIR}/test_retry${RETRY}.md, ${SESSION_DIR}/security_retry${RETRY}.md, ${SESSION_DIR}/review_retry${RETRY}.md, ${SESSION_DIR}/plan.md

ALL three must be STATUS: PASS for overall PASS. ANY FAIL means overall FAIL.

If PASS — write ${SESSION_DIR}/validation_retry${RETRY}.md:
FINAL: PASS
SUMMARY: <one sentence what was accomplished>

If FAIL — write ${SESSION_DIR}/validation_retry${RETRY}.md:
FINAL: FAIL
FAILED_CHECKS: <which checks failed>
FIX_INSTRUCTIONS:
- <exact fix with file/line/what to change>
- <be specific enough coder can fix without asking>

Also write just the FIX_INSTRUCTIONS to ${SESSION_DIR}/fix_retry$((RETRY+1)).md" \
"validation_retry${RETRY}.md"

    VAL_FILE="${SESSION_DIR}/validation_retry${RETRY}.md"

    if check_pass "$VAL_FILE"; then
        log ""
        log "✅ All checks PASSED after $RETRY retries!"
        break
    else
        FAILED=$(grep -i "FAILED_CHECKS:" "$VAL_FILE" 2>/dev/null | sed 's/.*FAILED_CHECKS: *//' || echo "unknown")
        RETRY=$((RETRY + 1))
        log "❌ Validation FAILED — retry #${RETRY} (failed: $FAILED)"
    fi

done

# ── COMMIT & PUSH ─────────────────────────────────────────────────
separator
log "📦 Committing..."

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
log "✓ Committed: $COMMIT_MSG"

if [ -n "$BRANCH_NAME" ]; then
    log "🔀 Merging $BRANCH_NAME → main"
    git checkout main
    git merge "$BRANCH_NAME" --no-ff -m "Merge: $COMMIT_MSG"
    git branch -d "$BRANCH_NAME"
    log "✓ Merged"
fi

git push origin main
log "✓ Pushed"

if [ -n "$ISSUE_NUM" ]; then
    gh issue close "$ISSUE_NUM" --comment "✅ Resolved in \`$COMMIT_MSG\` — $SUMMARY (retries: $RETRY)" 2>/dev/null || true
    gh issue edit "$ISSUE_NUM" --remove-label "in-progress" 2>/dev/null || true
    log "✓ Issue #$ISSUE_NUM closed"
fi

separator
log "🚀 Done! | Task: $PLAN_TASK | Retries: $RETRY | Logs: $SESSION_DIR"
separator
