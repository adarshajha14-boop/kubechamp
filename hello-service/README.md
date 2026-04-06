# Hello Service

A simple hello world microservice for KubeChamp platform.

## Quick Start

1. **Prerequisites**: Minikube, Docker, Helm, kubectl
2. **Start Minikube**: `minikube start && minikube addons enable ingress`
3. **Build & Deploy**: `docker build -t hello-service:latest . && minikube image load hello-service:latest && helm install hello-service ./helm-chart`
4. **Access**: `echo "$(minikube ip) hello-service.local" | sudo tee -a /etc/hosts && minikube tunnel`
5. **Visit**: `http://hello-service.local`

## Web-based Deployment UI

For a user-friendly deployment experience, use the included web UI:

```bash
cd deploy-ui
./start-ui.sh
# or manually:
# npm install && npm start
```

Then open `http://localhost:3000` in your browser and follow the step-by-step deployment guide.

## Detailed Deployment Guide

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for comprehensive step-by-step instructions, troubleshooting, and customization options.

## Project Structure

```
hello-service/
├── main.go              # Go application
├── go.mod               # Go dependencies
├── Dockerfile           # Container build
├── Makefile             # Build commands
├── README.md            # This file
├── DEPLOYMENT_GUIDE.md  # Detailed deployment guide
├── deploy-ui/           # Web-based deployment UI
│   ├── server.js        # Express server
│   ├── package.json     # Node.js dependencies
│   └── public/
│       └── index.html   # Web interface
└── helm-chart/          # Kubernetes manifests
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
```

## API

- **GET /**: Returns "Hello from KubeChamp!"
- **Port**: 8080 (internal), 80 (service)

## Development

```bash
# Local build
make build

# Docker build
make docker-build

# Clean
make clean
```