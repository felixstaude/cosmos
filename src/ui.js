import { PLANETS } from './planets.js';

const tooltip = document.getElementById('tooltip');
const detailPanel = document.getElementById('detail-panel');

let selectedPlanet = null;

export function getSelectedPlanet() {
  return selectedPlanet;
}

export function setSelectedPlanet(p) {
  selectedPlanet = p;
}

export function showTooltip(name, x, y) {
  tooltip.style.display = 'block';
  tooltip.style.left = (x + 16) + 'px';
  tooltip.style.top = (y - 10) + 'px';
  tooltip.textContent = name;
}

export function hideTooltip() {
  tooltip.style.display = 'none';
}

export function showPanel(data) {
  document.getElementById('panel-name').textContent = data.name;
  document.getElementById('panel-name').style.color =
    `rgb(${Math.round(data.color[0]*255)},${Math.round(data.color[1]*255)},${Math.round(data.color[2]*255)})`;
  document.getElementById('panel-type').textContent = data.type;
  const statsEl = document.getElementById('panel-stats');
  statsEl.innerHTML = '';
  const labels = { mass:'Mass', radius:'Radius', temp:'Surface Temp', gravity:'Gravity',
    day:'Day Length', year:'Orbital Period', atmosphere:'Atmosphere', pressure:'Pressure' };
  for (const [key, label] of Object.entries(labels)) {
    if (data.stats[key]) {
      statsEl.innerHTML += `<div class="stat-box"><div class="label">${label}</div><div class="value">${data.stats[key]}</div></div>`;
    }
  }
  document.getElementById('panel-desc').textContent = data.desc;
  detailPanel.style.display = 'block';
}

export function hidePanel() {
  detailPanel.style.display = 'none';
  selectedPlanet = null;
}

export function setupZoom(handleZoom, targetDistGetter) {
  const canvas = document.getElementById('canvas');
  canvas.addEventListener('wheel', (e) => { e.preventDefault(); handleZoom(e.deltaY * 0.1); }, { passive: false });
  document.getElementById('zoom-slider').addEventListener('input', (e) => { handleZoom(parseFloat(e.target.value), true); });
  document.getElementById('zoom-in').addEventListener('click', () => handleZoom(-15));
  document.getElementById('zoom-out').addEventListener('click', () => handleZoom(15));
  document.getElementById('close-panel').addEventListener('click', hidePanel);
}

export function updateZoomSlider(value) {
  document.getElementById('zoom-slider').value = value;
}

export function drawMinimap(planetObjects, camera) {
  const minimapCanvas = document.getElementById('minimap-canvas');
  const mctx = minimapCanvas.getContext('2d');
  const w = 180, h = 180, cx = w/2, cy = h/2, scale = 0.7;
  mctx.clearRect(0, 0, w, h);

  mctx.fillStyle = 'rgba(4,8,20,0.9)';
  mctx.beginPath(); mctx.arc(cx, cy, 88, 0, Math.PI*2); mctx.fill();

  PLANETS.forEach(p => {
    const r = p.orbitRadius * scale;
    mctx.strokeStyle = 'rgba(60,100,150,0.2)';
    mctx.lineWidth = 0.5;
    mctx.beginPath(); mctx.arc(cx, cy, r, 0, Math.PI*2); mctx.stroke();
  });

  const grad = mctx.createRadialGradient(cx, cy, 0, cx, cy, 5);
  grad.addColorStop(0, '#ffe080'); grad.addColorStop(1, 'rgba(255,180,50,0)');
  mctx.fillStyle = grad;
  mctx.beginPath(); mctx.arc(cx, cy, 5, 0, Math.PI*2); mctx.fill();
  mctx.fillStyle = '#ffe880';
  mctx.beginPath(); mctx.arc(cx, cy, 2, 0, Math.PI*2); mctx.fill();

  planetObjects.forEach((pObj) => {
    const r = pObj.data.orbitRadius * scale;
    const x = cx + Math.cos(pObj.angle) * r;
    const y = cy + Math.sin(pObj.angle) * r;
    const c = pObj.data.color;
    mctx.fillStyle = `rgb(${Math.round(c[0]*255)},${Math.round(c[1]*255)},${Math.round(c[2]*255)})`;
    const dotSize = Math.max(1.5, pObj.data.radius * 0.7);
    mctx.beginPath(); mctx.arc(x, y, dotSize, 0, Math.PI*2); mctx.fill();
  });

  const camX = cx + (camera.position.x * scale * 0.5);
  const camZ = cy + (camera.position.z * scale * 0.5);
  mctx.strokeStyle = 'rgba(126,184,255,0.7)';
  mctx.lineWidth = 1;
  mctx.beginPath(); mctx.arc(Math.max(cx-85,Math.min(cx+85,camX)), Math.max(cy-85,Math.min(cy+85,camZ)), 3, 0, Math.PI*2); mctx.stroke();
}
