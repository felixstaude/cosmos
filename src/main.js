import * as THREE from 'three';
import { PLANETS } from './planets.js';
import { STAR_VERT, STAR_FRAG, PLANET_VERT, ATMO_VERT, ATMO_FRAG, RING_VERT, RING_FRAG, getPlanetFrag } from './shaders.js';
import { showTooltip, hideTooltip, showPanel, hidePanel, setupZoom, updateZoomSlider, drawMinimap, setSelectedPlanet } from './ui.js';
import './style.css';

// ============================================================
// THREE.JS SETUP
// ============================================================
const canvas = document.getElementById('canvas');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.2;

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.1, 2000);
camera.position.set(0, 60, 120);

// Camera orbit controls (manual)
let camTheta = 0, camPhi = 0.6, camDist = 120, targetDist = 120;
let camTarget = new THREE.Vector3(0, 0, 0);
let isDragging = false, prevMouse = { x: 0, y: 0 };

// ============================================================
// STARFIELD
// ============================================================
function createStarfield() {
  const count = 6000;
  const geo = new THREE.BufferGeometry();
  const pos = new Float32Array(count * 3);
  const cols = new Float32Array(count * 3);
  const sizes = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    const r = 400 + Math.random() * 600;
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(2 * Math.random() - 1);
    pos[i*3] = r * Math.sin(phi) * Math.cos(theta);
    pos[i*3+1] = r * Math.sin(phi) * Math.sin(theta);
    pos[i*3+2] = r * Math.cos(phi);
    const temp = Math.random();
    if (temp < 0.3) { cols[i*3]=0.7; cols[i*3+1]=0.8; cols[i*3+2]=1.0; }
    else if (temp < 0.6) { cols[i*3]=1.0; cols[i*3+1]=0.95; cols[i*3+2]=0.8; }
    else { cols[i*3]=1.0; cols[i*3+1]=1.0; cols[i*3+2]=1.0; }
    sizes[i] = 0.5 + Math.random() * 1.5;
  }
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.BufferAttribute(cols, 3));
  geo.setAttribute('size', new THREE.BufferAttribute(sizes, 1));
  const mat = new THREE.PointsMaterial({ size: 1.2, vertexColors: true, transparent: true, opacity: 0.85, sizeAttenuation: false });
  scene.add(new THREE.Points(geo, mat));
}
createStarfield();

// ============================================================
// SUN
// ============================================================
const sunGeo = new THREE.SphereGeometry(5, 64, 64);
const sunMat = new THREE.ShaderMaterial({
  vertexShader: STAR_VERT, fragmentShader: STAR_FRAG,
  uniforms: { uTime: { value: 0 } }
});
const sun = new THREE.Mesh(sunGeo, sunMat);
scene.add(sun);

// Sun glow
const sunGlowGeo = new THREE.SphereGeometry(7.5, 32, 32);
const sunGlowMat = new THREE.ShaderMaterial({
  vertexShader: ATMO_VERT, fragmentShader: ATMO_FRAG,
  uniforms: { uColor: { value: new THREE.Color(1.0, 0.7, 0.2) }, uIntensity: { value: 2.0 } },
  transparent: true, side: THREE.BackSide, depthWrite: false
});
scene.add(new THREE.Mesh(sunGlowGeo, sunGlowMat));

// Sun light
const sunLight = new THREE.PointLight(0xffeedd, 2.0, 500);
scene.add(sunLight);
scene.add(new THREE.AmbientLight(0x1a2040, 0.4));

// ============================================================
// CREATE PLANETS
// ============================================================
const planetObjects = [];
const clickTargets = [];

PLANETS.forEach((pData, idx) => {
  const group = new THREE.Group();
  // Orbit line
  const orbitGeo = new THREE.BufferGeometry();
  const orbitPts = [];
  for (let i = 0; i <= 128; i++) {
    const a = (i / 128) * Math.PI * 2;
    orbitPts.push(Math.cos(a) * pData.orbitRadius, 0, Math.sin(a) * pData.orbitRadius);
  }
  orbitGeo.setAttribute('position', new THREE.Float32BufferAttribute(orbitPts, 3));
  const orbitLine = new THREE.Line(orbitGeo, new THREE.LineBasicMaterial({
    color: 0x1a3050, transparent: true, opacity: 0.3
  }));
  scene.add(orbitLine);

  // Planet mesh
  const geo = new THREE.SphereGeometry(pData.radius, 64, 64);
  const mat = new THREE.ShaderMaterial({
    vertexShader: PLANET_VERT, fragmentShader: getPlanetFrag(idx),
    uniforms: {
      uTime: { value: 0 },
      uColor: { value: new THREE.Color(...pData.color) },
      uLightDir: { value: new THREE.Vector3(1, 0.5, 0).normalize() }
    }
  });
  const mesh = new THREE.Mesh(geo, mat);
  group.add(mesh);

  // Atmosphere
  const atmoGeo = new THREE.SphereGeometry(pData.radius * 1.15, 32, 32);
  const atmoMat = new THREE.ShaderMaterial({
    vertexShader: ATMO_VERT, fragmentShader: ATMO_FRAG,
    uniforms: {
      uColor: { value: new THREE.Color(...pData.atmoColor) },
      uIntensity: { value: 1.5 }
    },
    transparent: true, side: THREE.BackSide, depthWrite: false
  });
  group.add(new THREE.Mesh(atmoGeo, atmoMat));

  // Rings
  if (pData.hasRings) {
    const ringGeo = new THREE.PlaneGeometry(pData.radius * 5, pData.radius * 5);
    const ringMat = new THREE.ShaderMaterial({
      vertexShader: RING_VERT, fragmentShader: RING_FRAG,
      uniforms: {
        uColor: { value: new THREE.Color(...pData.ringColor) },
        uTime: { value: 0 }
      },
      transparent: true, side: THREE.DoubleSide, depthWrite: false
    });
    const ring = new THREE.Mesh(ringGeo, ringMat);
    ring.rotation.x = -Math.PI / 2 + 0.15;
    ring.userData.isRing = true;
    group.add(ring);
  }

  // Moons
  for (let m = 0; m < pData.moons; m++) {
    const moonGeo = new THREE.SphereGeometry(pData.radius * 0.15, 16, 16);
    const moonMat = new THREE.MeshStandardMaterial({
      color: new THREE.Color(0.6 + m * 0.1, 0.6 + m * 0.05, 0.65),
      roughness: 0.9, metalness: 0.1
    });
    const moon = new THREE.Mesh(moonGeo, moonMat);
    moon.userData = { moonIdx: m, dist: pData.radius * (2.2 + m * 1.0), speed: 1.5 + m * 0.5 };
    group.add(moon);
  }

  group.rotation.z = pData.tilt;
  scene.add(group);

  planetObjects.push({
    group, mesh, data: pData, mat,
    angle: Math.random() * Math.PI * 2
  });
  clickTargets.push(mesh);
});

// ============================================================
// RAYCASTER & INTERACTION
// ============================================================
const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
let hoveredPlanet = null;

function onMouseMove(e) {
  mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;

  if (isDragging) {
    const dx = e.clientX - prevMouse.x;
    const dy = e.clientY - prevMouse.y;
    camTheta -= dx * 0.005;
    camPhi = Math.max(0.1, Math.min(Math.PI - 0.1, camPhi - dy * 0.005));
    prevMouse.x = e.clientX;
    prevMouse.y = e.clientY;
    return;
  }

  raycaster.setFromCamera(mouse, camera);
  const intersects = raycaster.intersectObjects(clickTargets);
  if (intersects.length > 0) {
    const obj = intersects[0].object;
    const pObj = planetObjects.find(p => p.mesh === obj);
    if (pObj) {
      hoveredPlanet = pObj;
      showTooltip(pObj.data.name, e.clientX, e.clientY);
      canvas.style.cursor = 'pointer';
    }
  } else {
    hoveredPlanet = null;
    hideTooltip();
    canvas.style.cursor = isDragging ? 'grabbing' : 'default';
  }
}

function onClick(e) {
  if (isDragging) return;
  raycaster.setFromCamera(mouse, camera);
  const intersects = raycaster.intersectObjects(clickTargets);
  if (intersects.length > 0) {
    const obj = intersects[0].object;
    const pObj = planetObjects.find(p => p.mesh === obj);
    if (pObj) {
      setSelectedPlanet(pObj);
      showPanel(pObj.data);
    }
  }
}

canvas.addEventListener('mousemove', onMouseMove);
canvas.addEventListener('click', onClick);
canvas.addEventListener('mousedown', (e) => {
  if (e.button === 0) { isDragging = false; prevMouse.x = e.clientX; prevMouse.y = e.clientY; }
});
window.addEventListener('mousemove', (e) => {
  if (e.buttons === 1) {
    const dx = Math.abs(e.clientX - prevMouse.x);
    const dy = Math.abs(e.clientY - prevMouse.y);
    if (dx > 3 || dy > 3) isDragging = true;
  }
});
canvas.addEventListener('mouseup', () => { setTimeout(() => isDragging = false, 10); });

// Zoom
function handleZoom(delta, absolute) {
  if (absolute) {
    targetDist = delta;
  } else {
    targetDist = Math.max(30, Math.min(250, targetDist + delta));
  }
  updateZoomSlider(targetDist);
}
setupZoom(handleZoom);

// ============================================================
// ANIMATION LOOP
// ============================================================
const clock = new THREE.Clock();
const _toSun = new THREE.Vector3();
const _lightDir = new THREE.Vector3();
const _normalMat = new THREE.Matrix3();

function animate() {
  requestAnimationFrame(animate);
  const t = clock.getElapsedTime();

  // Update sun
  sunMat.uniforms.uTime.value = t;

  // Update planets
  planetObjects.forEach((pObj) => {
    pObj.angle += pObj.data.orbitSpeed * 0.005;
    const x = Math.cos(pObj.angle) * pObj.data.orbitRadius;
    const z = Math.sin(pObj.angle) * pObj.data.orbitRadius;
    pObj.group.position.set(x, 0, z);
    pObj.mesh.rotation.y += pObj.data.rotationSpeed;
    pObj.mat.uniforms.uTime.value = t;

    // Light direction from sun
    _toSun.set(-x, 0, -z).normalize();
    _lightDir.copy(_toSun).applyMatrix3(_normalMat.setFromMatrix4(camera.matrixWorldInverse)).normalize();
    pObj.mat.uniforms.uLightDir.value.copy(_lightDir);

    // Rings
    pObj.group.children.forEach(child => {
      if (child.userData.isRing && child.material.uniforms) {
        child.material.uniforms.uTime.value = t;
      }
      // Moons
      if (child.userData.moonIdx !== undefined) {
        const md = child.userData;
        const ma = t * md.speed + md.moonIdx * 2.0;
        child.position.set(
          Math.cos(ma) * md.dist,
          Math.sin(ma * 0.3) * md.dist * 0.1,
          Math.sin(ma) * md.dist
        );
      }
    });
  });

  // Camera smoothing
  camDist += (targetDist - camDist) * 0.08;
  camera.position.x = camTarget.x + camDist * Math.sin(camPhi) * Math.sin(camTheta);
  camera.position.y = camTarget.y + camDist * Math.cos(camPhi);
  camera.position.z = camTarget.z + camDist * Math.sin(camPhi) * Math.cos(camTheta);
  camera.lookAt(camTarget);

  renderer.render(scene, camera);

  // Minimap at reduced rate
  if (Math.floor(t * 10) % 3 === 0) drawMinimap(planetObjects, camera);
}
animate();

// ============================================================
// RESIZE
// ============================================================
window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});
