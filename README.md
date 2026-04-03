# KubeChamp - Production-Grade Microservices Platform

A comprehensive, production-ready platform for deploying and managing microservices across multiple environments with enterprise-grade CI/CD, observability, security, and self-service developer tools.

## 🎯 Key Features

### Automation & Deployment
- **Automated CI/CD Pipeline** - GitHub Actions + GitLab CI with multi-stage builds
- **GitOps Deployment** - ArgoCD for declarative, automated deployments
- **Multi-Environment Support** - Dev, SIT, and Production environments with easy promotion
- **Canary & Blue-Green Deployments** - Progressive rollout strategies

### Observability (The Three Pillars)
- **Metrics** - Prometheus + Grafana dashboards
- **Logging** - ELK Stack (Elasticsearch, Logstash, Kibana) with log aggregation
- **Tracing** - Jaeger distributed tracing for request flows
- **Alerting** - Alert Manager for intelligent alerting and routing

### Security
- **RBAC** - Role-based access control with service accounts
- **Secrets Management** - HashiCorp Vault integration
- **Network Policies** - Microservice network isolation
- **Image Scanning** - Trivy for container image vulnerability scanning
- **Pod Security Policies** - Runtime security enforcement
- **Audit Logging** - Complete audit trails for compliance

### Service Routing & Load Balancing
- **API Gateway** - Kong for API management and routing
- **Service Mesh** - Istio for advanced traffic management
- **Ingress Controller** - Nginx Ingress with auto-scaling
- **Load Balancing** - Smart traffic distribution

### Developer Experience
- **Self-Service CLI** - `kc` command-line tool for developers
- **Developer Dashboard** - Web UI for service management
- **Service Templates** - Quick scaffolding for new microservices
- **Local Development** - Docker Compose + Skaffold for local dev

---

## 📁 Project Structure

```
kubechamp/
├── infrastructure/           # IaC for all environments
│   └── terraform/
│       ├── modules/          # Reusable Terraform modules
│       └── environments/      # Dev, SIT, Prod configurations
├── platform/                 # Core platform components
│   ├── helm-charts/          # Helm charts for platform services
│   │   ├── platform-core/    # Core platform services
│   │   ├── observability/    # Prometheus, Grafana, ELK, Jaeger
│   │   ├── security/         # Vault, RBAC, policies
│   │   └── networking/       # Kong API Gateway, Istio ingress
│   └── scripts/              # Deployment scripts
├── ci-cd/                    # CI/CD configurations
│   ├── github-actions/       # GitHub Actions workflows
│   ├── gitlab-ci/            # GitLab CI/CD pipelines
│   └── argocd/               # ArgoCD configs for GitOps
├── developer-tools/          # Developer self-service tools
│   ├── cli/                  # KubeChamp CLI tool
│   ├── sdk/                  # Developer SDKs
│   └── dashboards/           # Web dashboards
├── example-services/         # Reference microservices
├── templates/                # Service templates & scaffolding
└── docs/                     # Documentation & guides
```

---

## 🚀 Quick Start

### Prerequisites
- Kubernetes 1.24+ cluster (can provision with Terraform)
- `kubectl`, `helm`, `terraform` installed
- AWS/GCP/Azure account (for cloud infrastructure)

### Option 1: Deploy with Terraform (Recommended)

```bash
# Clone and navigate
cd infrastructure/terraform/environments

# Deploy development environment
cd dev
terraform init
terraform plan
terraform apply

# Deploy to SIT/Prod similarly
```

### Option 2: Deploy to Existing Cluster

```bash
# Install platform helm charts
helm repo add kubechamp https://charts.kubechamp.io
helm install kubechamp-platform kubechamp/platform-core -n platform --create-namespace

# Install observability stack
helm install observability kubechamp/observability -n observability --create-namespace

# Install security layer
helm install security kubechamp/security -n security --create-namespace
```

### Option 3: Local Development with Docker Compose

```bash
docker-compose up -d
# Platform available at http://localhost:8080
```

---

## 👨‍💻 Developer Self-Service

### Install KubeChamp CLI

```bash
curl -sSL https://install.kubechamp.io | bash
```

### Deploy a New Microservice

```bash
# Create new service from template
kc init my-service --template go-rest-api

# Deploy to dev environment
kc deploy --env dev

# Promote to SIT
kc promote --from dev --to sit

# Promote to production (with approval)
kc promote --from sit --to prod --require-approval
```

### View Service Status

```bash
# Get service overview
kc status my-service

# Check logs across all replicas
kc logs my-service --tail 100 --follow

# Get metrics and alerts
kc metrics my-service
```

### Access the Dashboard

Navigate to: `https://dashboard.kubechamp.io`

---

## 🔍 Observability

### Access Grafana Dashboards
- **URL**: http://grafana.kubechamp.io
- **Default Credentials**: admin/admin
- **Dashboards**: 
  - Cluster Overview
  - Service Health
  - Application Metrics
  - Resource Utilization

### View Logs (Kibana)
- **URL**: http://kibana.kubechamp.io
- **Log Sources**: All container logs, application logs, audit logs

### Trace Requests (Jaeger)
- **URL**: http://jaeger.kubechamp.io
- **Features**: End-to-end request tracing, latency analysis

---

## 🔐 Security Features

### Authentication & Authorization
- Service-to-service mTLS via Istio
- RBAC for API access
- OAuth2/OIDC integration for dashboards

### Secrets Management
- HashiCorp Vault integration
- Automatic secret rotation
- Audit logging for secret access

### Image Security
- Container image scanning at build time
- Runtime admission controllers
- Signed images verification

### Network Security
- Network policies for service isolation
- Ingress WAF rules
- DDoS protection

---

## 📊 Platform Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Developer Self-Service                 │
│  (CLI, Dashboard, Templates, SDKs)                      │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                   CI/CD Operations                       │
│  (GitHub Actions, GitLab CI, ArgoCD)                   │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│            Platform Control Plane (K8s)                 │
│  ┌────────────────┐     ┌──────────────┐                │
│  │ Security Layer │     │ API Gateway  │                │
│  │ (Vault, RBAC) │     │ (Kong, OAuth)│                │
│  └────────────────┘     └──────────────┘                │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│         Microservices Layer (Istio Service Mesh)        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │ Service │  │ Service │  │ Service │  │ Service │   │
│  │   A     │  │   B     │  │   C     │  │   D     │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│          Observability Stack (Telemetry)                │
│  ┌────────────┐  ┌───────────┐  ┌────────┐             │
│  │ Prometheus │  │ Jaeger    │  │ ELK    │             │
│  └────────────┘  └───────────┘  └────────┘             │
│  ┌────────────────────────────────────────────┐        │
│  │    Grafana Dashboards & Alerts             │        │
│  └────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Multi-Environment Workflow

### Environment Progression

```
Code Commit
    │
    ▼
GitHub Actions / GitLab CI (Build & Test)
    │
    ├─── Artifact Registry (Container image + scan)
    │
    ▼
ArgoCD (Automatic promotion)
    │
    ├─── DEV Environment (Auto-deploy)
    │    ├─── Smoke Tests
    │    ├─── Integration Tests
    │    └─── Manual Testing
    │
    ├─── SIT Environment (Manual promotion)
    │    ├─── UAT
    │    ├─── Performance Tests
    │    └─── Security Validation
    │
    └─── PROD Environment (Approval required)
         ├─── Canary Deployment
         ├─── Monitoring & Alerts
         └─── Rollback Ready
```

---

## 🛠️ Available Commands

### Infrastructure
```bash
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
```

### Helm Deployments
```bash
helm install platform ./platform/helm-charts/platform-core -n platform --create-namespace
helm upgrade platform ./platform/helm-charts/platform-core -n platform
helm uninstall platform -n platform
```

### Developer CLI
```bash
kc init <service-name>           # Create new service
kc deploy --env <environment>    # Deploy service
kc promote --from <env> --to <env>  # Promote between envs
kc logs <service>                # View service logs
kc metrics <service>             # View service metrics
kc status <service>              # Get service status
```

---

## 📚 Documentation

- [Infrastructure Setup](./docs/infrastructure-setup.md)
- [Platform Deployment](./docs/platform-deployment.md)
- [Developer Guide](./docs/developer-guide.md)
- [CI/CD Pipeline](./docs/ci-cd-pipeline.md)
- [Observability Guide](./docs/observability-guide.md)
- [Security Best Practices](./docs/security.md)
- [Troubleshooting](./docs/troubleshooting.md)

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - See [LICENSE](./LICENSE) file

---

## 🆘 Support

- **Documentation**: https://docs.kubechamp.io
- **Issues**: GitHub Issues
- **Community**: Slack channel #kubechamp
- **Email**: support@kubechamp.io
