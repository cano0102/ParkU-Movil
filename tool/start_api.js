#!/usr/bin/env node
/**
 * Levanta Api-ParkU (el backend) si no está corriendo ya.
 *
 * Lo usan las tareas de VS Code (.vscode/tasks.json) antes de correr la app, y
 * se puede correr a mano: `node tool/start_api.js`.
 *
 * Dónde busca la API, en este orden:
 *   1. La variable de entorno PARKU_API_DIR.
 *   2. ../Api-ParkU        (clonada como hermana de este repo)
 *   3. ../../Documents/Api-ParkU  (donde suele estar en este equipo)
 *
 * Si http://localhost:PUERTO/api/health ya responde, no hace nada (así se puede
 * dejar la API abierta en otra terminal sin que choque el puerto).
 */
const { spawn } = require('child_process');
const fs = require('fs');
const http = require('http');
const path = require('path');

const raiz = path.resolve(__dirname, '..');
const candidatos = [
  process.env.PARKU_API_DIR,
  path.join(raiz, '..', 'Api-ParkU'),
  path.join(raiz, '..', '..', 'Documents', 'Api-ParkU'),
].filter(Boolean);

const dirApi = candidatos.find((d) => fs.existsSync(path.join(d, 'package.json')));
if (!dirApi) {
  console.error('No encontré Api-ParkU. Clónala junto a este repo (../Api-ParkU) o define PARKU_API_DIR.');
  console.error('Rutas revisadas:\n  - ' + candidatos.join('\n  - '));
  process.exit(1);
}

const puerto = leerPuerto(dirApi);

function leerPuerto(dir) {
  try {
    const env = fs.readFileSync(path.join(dir, '.env'), 'utf8');
    const m = env.match(/^\s*PORT\s*=\s*(\d+)/m);
    if (m) return Number(m[1]);
  } catch (_) {}
  return 3000;
}

function health(cb) {
  const req = http.get({ host: '127.0.0.1', port: puerto, path: '/api/health', timeout: 2000 }, (res) => {
    res.resume();
    cb(res.statusCode === 200);
  });
  req.on('error', () => cb(false));
  req.on('timeout', () => { req.destroy(); cb(false); });
}

health((arriba) => {
  if (arriba) {
    console.log(`Api-ParkU ya está corriendo en http://localhost:${puerto} (Servidor ejecutándose en puerto ${puerto})`);
    return;
  }
  if (!fs.existsSync(path.join(dirApi, 'node_modules'))) {
    console.error(`Falta node_modules en ${dirApi}. Corre "npm install" ahí primero.`);
    process.exit(1);
  }
  if (!fs.existsSync(path.join(dirApi, '.env'))) {
    console.error(`Falta el archivo .env en ${dirApi} (copia .env.example y complétalo).`);
    process.exit(1);
  }
  console.log(`Iniciando Api-ParkU desde ${dirApi} ...`);
  const hijo = spawn('npm', ['run', 'dev'], { cwd: dirApi, stdio: 'inherit', shell: true });
  hijo.on('exit', (codigo) => process.exit(codigo ?? 0));
  for (const senal of ['SIGINT', 'SIGTERM']) {
    process.on(senal, () => hijo.kill(senal));
  }
});
