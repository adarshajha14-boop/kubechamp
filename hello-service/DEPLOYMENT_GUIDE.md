# Deploying Hello Service on KubeChamp

This guide provides step-by-step instructions for deploying the Hello Service, a basic microservice example, on a KubeChamp platform using Minikube for local development.

## Web-based Deployment UI

For an interactive deployment experience, use the included web UI:

```bash
cd deploy-ui
npm install
npm start
# or
node server.js
```

Then open `http://localhost:3000` in your browser. The UI provides one-click buttons for each deployment step with real-time output.

## Prerequisites

Before deploying, ensure you have the following installed:

- **Minikube**: Local Kubernetes cluster
- **Docker**: Container runtime
- **Helm**: Kubernetes package manager (v3+)
- **kubectl**: Kubernetes CLI tool
- **Node.js** (optional, for web UI)

### Installation Commands

```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
curl https://get.helm.sh/helm-v3.17.3-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# Install kubectl (if not already installed)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Install Node.js (for web UI)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Step 1: Start Minikube Cluster

Start your local Kubernetes cluster with ingress enabled:

```bash
minikube start
minikube addons enable ingress
```

Verify the cluster is running:
```bash
minikube status
kubectl get nodes
```

## Step 2: Build the Application

Navigate to the hello-service directory and build the Docker image:

```bash
cd hello-service

# Build the Docker image
docker build -t hello-service:latest .
```

## Step 3: Load Image into Minikube

Since Minikube uses its own Docker environment, load the image:

```bash
minikube image load hello-service:latest
```

## Step 4: Deploy with Helm

Deploy the service using the provided Helm chart:

```bash
helm install hello-service ./helm-chart
```

Monitor the deployment:
```bash
kubectl get pods
kubectl get services
kubectl get ingress
```

Wait for the pod to be in `Running` status.

## Step 5: Access the Service

The service is exposed via Ingress. Set up local DNS resolution:

```bash
# Add to /etc/hosts (requires sudo)
echo "$(minikube ip) hello-service.local" | sudo tee -a /etc/hosts
```

Start the Minikube tunnel to enable ingress access:
```bash
minikube tunnel
```

Now access the service:
- **URL**: `http://hello-service.local`
- **Test with curl**: `curl http://hello-service.local`
- **Expected Response**: `Hello from KubeChamp!`

## Step 6: Verify Deployment

Check the application logs:
```bash
kubectl logs -l app.kubernetes.io/name=hello-service
```

Test the health endpoint (if implemented):
```bash
curl http://hello-service.local/health
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**:
   - Ensure the image is built and loaded: `minikube image load hello-service:latest`
   - Check image exists: `minikube image ls | grep hello-service`

2. **Ingress Not Accessible**:
   - Verify ingress controller: `kubectl get pods -n ingress-nginx`
   - Check tunnel is running: `minikube tunnel` (in another terminal)
   - Confirm hosts file entry

3. **Service Not Starting**:
   - Check pod status: `kubectl describe pod <pod-name>`
   - View logs: `kubectl logs <pod-name>`

### Useful Commands

```bash
# View all resources
kubectl get all

# Debug ingress
kubectl describe ingress hello-service

# Check service endpoints
kubectl get endpoints

# Port forward for direct access (alternative to ingress)
kubectl port-forward svc/hello-service 8080:80
# Then access: http://localhost:8080
```

## Step 7: Cleanup

To remove the deployment:

```bash
# Uninstall Helm release
helm uninstall hello-service

# Stop tunnel (if running)
pkill -f "minikube tunnel"

# Stop Minikube
minikube stop

# Delete cluster (optional)
minikube delete
```

## Service Architecture

The Hello Service includes:

- **Go Application**: Simple HTTP server on port 8080
- **Docker Container**: Multi-stage build for optimization
- **Kubernetes Deployment**: Single replica with health checks
- **Service**: ClusterIP for internal communication
- **Ingress**: External access via nginx ingress controller

## Customization

### Scaling
Update replica count in `helm-chart/values.yaml`:
```yaml
replicaCount: 3
```

Upgrade the release:
```bash
helm upgrade hello-service ./helm-chart
```

### Environment Variables
Add environment variables in the deployment template or values.yaml.

### Custom Domain
Modify the ingress host in `helm-chart/values.yaml`:
```yaml
ingress:
  hosts:
    - host: "my-custom-domain.local"
```

## Next Steps

- Explore the KubeChamp platform for production deployments
- Add monitoring, logging, and security features
- Integrate with CI/CD pipelines
- Deploy additional microservices

For more advanced KubeChamp features, refer to the main platform documentation in the `/docs` directory.