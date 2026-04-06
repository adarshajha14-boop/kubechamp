const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const app = express();
const server = require('http').createServer(app);
const io = require('socket.io')(server);

const PORT = 3000;

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// API endpoint to execute commands
app.post('/execute/:command', (req, res) => {
  const command = req.params.command;
  const commands = {
    'start-minikube': 'minikube start && minikube addons enable ingress',
    'build-image': 'cd /home/aj/Documents/kubechamp/hello-service && docker build -t hello-service:latest .',
    'load-image': 'minikube image load hello-service:latest',
    'deploy-service': 'cd /home/aj/Documents/kubechamp/hello-service && helm install hello-service ./helm-chart',
    'setup-dns': 'echo "$(minikube ip) hello-service.local" | sudo tee -a /etc/hosts',
    'start-tunnel': 'minikube tunnel',
    'check-status': 'kubectl get pods && kubectl get services && kubectl get ingress',
    'cleanup': 'helm uninstall hello-service && pkill -f "minikube tunnel"'
  };

  if (commands[command]) {
    exec(commands[command], (error, stdout, stderr) => {
      const result = {
        command: commands[command],
        success: !error,
        output: stdout,
        error: stderr
      };
      res.json(result);
    });
  } else {
    res.status(400).json({ error: 'Unknown command' });
  }
});

// Socket.IO for real-time updates
io.on('connection', (socket) => {
  console.log('Client connected');

  socket.on('execute-command', (command) => {
    const commands = {
      'start-minikube': 'minikube start && minikube addons enable ingress',
      'build-image': 'cd /home/aj/Documents/kubechamp/hello-service && docker build -t hello-service:latest .',
      'load-image': 'minikube image load hello-service:latest',
      'deploy-service': 'cd /home/aj/Documents/kubechamp/hello-service && helm install hello-service ./helm-chart',
      'setup-dns': 'echo "$(minikube ip) hello-service.local" | sudo tee -a /etc/hosts',
      'start-tunnel': 'minikube tunnel',
      'check-status': 'kubectl get pods && kubectl get services && kubectl get ingress',
      'cleanup': 'helm uninstall hello-service && pkill -f "minikube tunnel"'
    };

    if (commands[command]) {
      const child = exec(commands[command]);

      child.stdout.on('data', (data) => {
        socket.emit('command-output', { type: 'stdout', data: data.toString() });
      });

      child.stderr.on('data', (data) => {
        socket.emit('command-output', { type: 'stderr', data: data.toString() });
      });

      child.on('close', (code) => {
        socket.emit('command-output', { type: 'exit', code });
      });
    }
  });
});

server.listen(PORT, () => {
  console.log(`Deployment UI server running at http://localhost:${PORT}`);
});