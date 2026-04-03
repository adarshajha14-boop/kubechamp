# KubeChamp Developer Guide

## Quick Start for Developers

### Installation

```bash
# Install KubeChamp CLI
curl -sSL https://install.kubechamp.io | bash

# Or manually add to your PATH
chmod +x ./developer-tools/cli/kc
export PATH="$PATH:$(pwd)/developer-tools/cli"
```

### Create Your First Microservice

```bash
# Create a new Go microservice
kc init my-awesome-service go-rest-api

# Navigate to the service directory
cd my-awesome-service

# Deploy to development environment
kc deploy --env dev

# Check the deployment status
kc status my-awesome-service --env dev

# View logs
kc logs my-awesome-service --env dev --tail 50 --follow
```

---

## Service Templates

### 1. Go REST API

Best for: High-performance APIs, backend services

```bash
kc init my-service go-rest-api
```

Includes:
- Dockerfile optimized for Go
- Example HTTP server with health check
- Prometheus metrics middleware
- Makefile for building and testing

### 2. Node.js Express

Best for: Real-time applications, flexible APIs

```bash
kc init my-service node-express
```

Includes:
- Multi-stage Dockerfile
- Express.js setup
- NPM scripts for dev/test/build
- Docker-compose for local development

### 3. Python FastAPI

Best for: Data processing, AI/ML services

```bash
kc init my-service python-fastapi
```

Includes:
- FastAPI application structure
- Poetry for dependency management
- Uvicorn server configuration
- Async support

---

## Development Workflow

### Step 1: Write Your Service

```bash
# Example: Go service structure
my-service/
├── main.go                 # Application code
├── Dockerfile             # Container definition
├── go.mod                 # Dependencies
├── helm-chart/            # Kubernetes manifests
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── Makefile               # Build commands
└── README.md
```

### Step 2: Local Development

```bash
# Build locally
make build

# Run with Docker
docker build -t my-service:latest .
docker run -p 8080:8080 my-service:latest

# Test
make test

# Lint
make lint
```

### Step 3: Deploy to Development

```bash
kc deploy --env dev
```

### Step 4: Test Your Service

```bash
# Check status
kc status my-service --env dev

# View metrics
kc metrics my-service --env dev

# View logs
kc logs my-service --env dev --follow
```

### Step 5: Promote to Other Environments

```bash
# Move to SIT for system testing
kc promote dev sit

# Move to production (requires approval)
kc promote sit prod --require-approval
```

---

## Configuration Management

### Environment Variables

```yaml
# values-dev.yaml
env:
  - name: LOG_LEVEL
    value: "debug"
  - name: DATABASE_URL
    value: "postgres://db:5432/dev"

# values-prod.yaml
env:
  - name: LOG_LEVEL
    value: "info"
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: url
```

### Secrets Management

```bash
# Create a sealed secret
kubectl create secret generic my-secret --from-literal=password=secret \
    --dry-run=client -o yaml | \
    kubeseal -f - > sealed-secret.yaml

# Apply sealed secret
kubectl apply -f sealed-secret.yaml

# In Helm values
secretRef:
  name: my-secret
  key: password
```

---

## Observability

### Logging

All logs from your service are automatically aggregated in Kibana.

```bash
# View logs for your service
kc logs my-service --env dev --tail 100

# Open Kibana dashboard
kc dashboard --env dev
# Search for: service:"my-service"
```

### Metrics

Expose Prometheus metrics from your application.

```bash
// Go example
import "github.com/prometheus/client_golang/prometheus"

counter := prometheus.NewCounter(prometheus.CounterOpts{
    Name: "requests_total",
    Help: "Total requests",
})
```

### Tracing

Distributed tracing helps visualize request flows.

```bash
// Go example
import "go.opentelemetry.io/otel"

tracer := otel.Tracer("my-service")
ctx, span := tracer.Start(ctx, "operation-name")
defer span.End()
```

---

## Best Practices

### 1. Resource Management

```yaml
# Always specify requests and limits
resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 2. Health Checks

```bash
# Implement both liveness and readiness probes
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 3. Graceful Shutdown

```bash
# Handle SIGTERM signal
terminationGracePeriodSeconds: 30
```

### 4. Security

```yaml
# Run as non-root user
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

### 5. Monitoring & Alerting

```yaml
# Add Prometheus annotations
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

---

## Debugging

### View Service PODs

```bash
# List all pods for your service
kubectl get pods -l app=my-service

# Get detailed pod info
kubectl describe pod my-service-xxxxx

# Get pod events
kubectl get events --field-selector involvedObject.name=my-service-xxxxx
```

### Check Logs

```bash
# View current logs
kubectl logs pod/my-service-xxxxx

# View previous logs (if pod crashed)
kubectl logs pod/my-service-xxxxx --previous

# Stream logs
kubectl logs pod/my-service-xxxxx -f
```

### Port Forward

```bash
# Access service locally
kubectl port-forward svc/my-service 8080:80
curl http://localhost:8080
```

### Execute Commands in Pod

```bash
# Run command in pod
kubectl exec pod/my-service-xxxxx -- ls -la

# Open bash shell
kubectl exec -it pod/my-service-xxxxx -- /bin/bash
```

---

## Common Issues

### Pod Not Starting

```bash
# Check events
kubectl describe pod <pod-name>

# Check resource availability
kubectl top nodes

# Increase resource limits in values.yaml
resources:
  limits:
    cpu: 1000m
    memory: 1024Mi
```

### Image Pull Errors

```bash
# Verify image exists in registry
aws ecr describe-images --repository-name my-service

# Check image pull secrets
kubectl get secrets -o jsonpath='{.items[*].metadata.name}'
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints my-service

# Check ingress
kubectl get ingress -o wide

# Test DNS
kubectl run -it --rm debug --image=alpine -- nslookup my-service.default.svc.cluster.local
```

---

## CI/CD Integration

### GitHub Actions

Your repository will automatically:
1. Build Docker image
2. Scan for vulnerabilities
3. Run tests
4. Run security checks
5. Push to registry
6. Deploy to dev (automatically)
7. Deploy to sit (on main branch)
8. Deploy to prod (with approval)

### Manual Trigger

```bash
# Trigger workflow via CLI
gh workflow run build-deploy.yml -f environment=dev
```

---

## Performance Testing

```bash
# Load testing with Apache Bench
ab -n 1000 -c 10 http://my-service.kubechamp.io/

# Using wrk for concurrent requests
wrk -t 4 -c 100 -d 30s http://my-service.kubechamp.io/

# View metrics in Grafana during test
kc dashboard --env dev
```

---

## Deployment Strategies

### Canary Deployment

```yaml
# Using Flagger for canary deployments
canary:
  enabled: true
  weight: 10  # Start with 10% traffic
  analysis:
    interval: 1m
    threshold: 5
    metrics:
      - name: error_rate
        thresholdRange:
          max: 0.05
```

### Rolling Update

```yaml
# Default strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

### Blue-Green Deployment

```bash
# Deploy new version (green)
kc deploy --env prod

# Switch traffic to new version
kubectl set selector svc/my-service version=new
```

---

## Additional Resources

- [KubeChamp Platform Docs](https://docs.kubechamp.io)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Charts](https://chart-releaser.github.io/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Istio Documentation](https://istio.io/latest/docs/)

---

## Getting Help

- **Slack Channel**: #kubechamp (for questions and discussions)
- **Issues**: [GitHub Issues](https://github.com/kubechamp/platform/issues)
- **Email**: support@kubechamp.io
- **Documentation**: https://docs.kubechamp.io
