const http = require('http');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../build/web');
const types = {'.html':'text/html', '.js':'text/javascript', '.json':'application/json',
 '.wasm':'application/wasm', '.png':'image/png', '.wav':'audio/wav', '.ttf':'font/ttf', '.css':'text/css'};
http.createServer((req, res) => {
  let file;
  try { file = path.resolve(root, '.' + decodeURIComponent(new URL(req.url, 'http://localhost').pathname)); }
  catch { res.writeHead(400); return res.end(); }
  if (file !== root && !file.startsWith(root + path.sep)) { res.writeHead(403); return res.end(); }
  if (file === root) file = path.join(root, 'index.html');
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); return res.end('Not found'); }
    res.writeHead(200, {'Content-Type': types[path.extname(file)] || 'application/octet-stream', 'Cache-Control':'no-store'});
    res.end(data);
  });
}).listen(8787, '127.0.0.1', () => console.log('ArrowNova: http://127.0.0.1:8787'));
