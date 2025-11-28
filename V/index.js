const http = require('http');

const server = http.createServer((req, res) => {
  console.log(`Solicitud recibida: ${req.method} ${req.url}`);
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`
    <html>
      <head>
        <title>Infraestructura Para TI</title>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          h1 { color: #333; }
          .success { color: green; }
        </style>
      </head>
      <body>
        <h1>Aplicacion Dockerizada Funcionando</h1>
        <p><strong>Node.js:</strong> ${process.version}</p>
        <p><strong>Plataforma:</strong> ${process.platform}</p>
        <p><strong>Hora del servidor:</strong> ${new Date().toISOString()}</p>
        <p><strong>Directorio de trabajo:</strong> ${process.cwd()}</p>
        <hr>
        <p class="success">Contenedor Docker ejecutandose correctamente</p>
      </body>
    </html>
  `);
});

const PORT = process.env.PORT || 3000;

// Escuchar en 0.0.0.0 para que sea accesible desde fuera del contenedor
server.listen(PORT, '0.0.0.0', () => {
  console.log('Servidor ejecutandose en http://0.0.0.0:' + PORT);
  console.log('Listo para recibir solicitudes...');
});

// Manejar señales de terminación correctamente
process.on('SIGINT', () => {
  console.log('Recibido SIGINT. Cerrando servidor...');
  server.close(() => {
    console.log('Servidor cerrado correctamente.');
    process.exit(0);
  });
});

process.on('SIGTERM', () => {
  console.log('Recibido SIGTERM. Cerrando servidor...');
  server.close(() => {
    console.log('Servidor cerrado correctamente.');
    process.exit(0);
  });
});
