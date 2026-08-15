import http from 'node:http';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const port = Number(process.env.OMOLAAT_RUNNER_PORT || 8787);
const nodeBin = process.execPath;

function runImport() {
  return new Promise((resolve) => {
    const child = spawn(nodeBin, [path.join(root, 'tool/omolaat-auto-import.mjs')], {
      cwd: root,
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString();
    });
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });
    child.on('close', (code) => {
      resolve({ code, stdout: stdout.trim(), stderr: stderr.trim() });
    });
  });
}

const server = http.createServer(async (req, res) => {
  if (req.method !== 'POST' || req.url !== '/run') {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
    return;
  }

  const result = await runImport();
  res.writeHead(result.code === 0 ? 200 : 500, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(result));
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Omolaat local runner listening on http://127.0.0.1:${port}`);
});
