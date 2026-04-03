# KubeChamp Platform Deployment Guide

## Prerequisites

### Required Tools
- AWS CLI v2
- Terraform >= 1.0
- kubectl >= 1.24
- Helm >= 3.10
- Git
- Docker (for local development)

### AWS Requirements
- AWS Account with appropriate permissions
- IAM credentials configured
- At least one AWS region configured

### Networking Requirements
- VPC with sufficient CIDR range (we use 10.0.0.0/16, 10.1.0.0/16, 10.2.0.0/16)
- Internet access for pulling container images

---

## Phase 1: Infrastructure Setup with Terraform

### Step 1: Initialize Terraform Backend (Shared State)

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
    --bucket kubechamp-terraform-state-$(aws sts get-caller-identity --query Account --output text) \
    --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket kubechamp-terraform-state-$(aws sts get-caller-identity --query Account --output text) \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for locks
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### Step 2: Deploy Development Environment

```bash
cd infrastructure/terraform/environments/dev

# Initialize Terraform
terraform init

# Create and review plan
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Output cluster endpoints
terraform output cluster_endpoint
terraform output ecr_repository_url
```

### Step 3: Configure kubectl for Development Cluster

```bash
aws eks update-kubeconfig \
    --name kubechamp-dev \
    --region us-east-1

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 4: Repeat for SIT and Production

```bash
# SIT Environment
cd ../sit
terraform init
terraform plan -out=tfplan
terraform apply tfplan
aws eks update-kubeconfig --name kubechamp-sit --region us-east-1

# Production Environment (with extra caution)
cd ../prod
terraform init
terraform plan -out=tfplan
# Review plan carefully!
terraform apply tfplan
aws eks update-kubeconfig --name kubechamp-prod --region us-east-1
```

---

## Phase 2: Platform Core Services Deployment

### Step 1: Add Helm Repositories

```bash
helm repo add stable https://charts.helm.sh/stable
helm repo add nginx-stable https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add elastic https://helm.elastic.co
helm repo add jaeger https://jaegertracing.github.io/helm-charts
helm repo add vault https://helm.releases.hashicorp.com
helm repo add jetstack https://charts.jetstack.io

helm repo update
```

### Step 2: Deploy cert-manager (Required for TLS)

```bash
# Install cert-manager
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@kubechamp.io
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### Step 3: Deploy Platform Core (Ingress & API Gateway)

```bash
# Set environment variable
export ENV=dev

# Deploy platform core
helm install kubechamp-platform ./platform/helm-charts/platform-core \
    --namespace platform \
    --create-namespace \
    --values ./platform/helm-charts/platform-core/values.yaml \
    --set environment=$ENV \
    --wait --timeout 5m
```

### Step 4: Deploy Observability Stack

```bash
helm install observability ./platform/helm-charts/observability \
    --namespace observability \
    --create-namespace \
    --values ./platform/helm-charts/observability/values.yaml \
    --set environment=$ENV \
    --wait --timeout 10m
```

### Step 5: Deploy Security Layer

```bash
helm install security ./platform/helm-charts/security \
    --namespace security \
    --create-namespace \
    --values ./platform/helm-charts/security/values.yaml \
    --set environment=$ENV \
    --wait --timeout 5m
```

### Step 6: Deploy Networking Components

```bash
helm install networking ./platform/helm-charts/networking \
    --namespace networking \
    --create-namespace \
    --values ./platform/helm-charts/networking/values.yaml \
    --set environment=$ENV \
    --wait --timeout 5m
```

---

## Phase 3: GitOps Setup with ArgoCD

### Step 1: Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### Step 2: Deploy ArgoCD Configuration

```bash
kubectl apply -f ./ci-cd/argocd/argocd-config.yaml
```

### Step 3: Access ArgoCD UI

```bash
# Port forward to locally access ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access at https://localhost:8080
```

### Step 4: Connect Git Repository

```bash
# Generate SSH key for ArgoCD
ssh-keygen -t rsa -b 4096 -f ~/.ssh/argocd -N ""

# Add public key to GitHub/GitLab repository deploy keys

# Configure ArgoCD to use the key
kubectl create secret generic argocd-git-credentials \
    --from-file=sshPrivateKeySecret=$HOME/.ssh/argocd \
    -n argocd
```

---

## Phase 4: CI/CD Pipeline Setup

### Step 1: Configure GitHub Actions (if using GitHub)

```bash
# Set up required secrets in GitHub repository settings:
# - AWS_ROLE_TO_ASSUME: IAM role ARN for OIDC
# - SONAR_TOKEN: SonarCloud token
# - SLACK_WEBHOOK: Slack webhook for notifications
```

### Step 2: Create IAM Role for GitHub Actions OIDC

```bash
# This allows GitHub Actions to assume an IAM role without credentials

# Create trust policy JSON
cat > github-oidc-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
    --role-name github-actions-role \
    --assume-role-policy-document file://github-oidc-trust-policy.json

# Attach necessary policies
aws iam attach-role-policy \
    --role-name github-actions-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSFullAccess

aws iam attach-role-policy \
    --role-name github-actions-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### Step 3: Deploy Example Microservice

```bash
cd example-services/user-service
kc deploy --env dev
kc promote dev sit
```

---

## Phase 5: Verification and Testing

### Step 1: Verify Cluster Health

```bash
# Check all nodes
kubectl get nodes -o wide

# Check all namespaces
kubectl get namespaces

# Check platform services
kubectl get pods -n platform
kubectl get pods -n observability
kubectl get pods -n security
```

### Step 2: Verify Ingress Configuration

```bash
# Get ingress IPs
kubectl get ingress -A

# Test endpoints
curl http://api.kubechamp.io/health
```

### Step 3: Access Observability Dashboards

```bash
# Grafana
kubectl port-forward -n observability svc/grafana 3000:80
# Access at http://localhost:3000

# Prometheus
kubectl port-forward -n observability svc/prometheus 9090:9090
# Access at http://localhost:9090

# Kibana
kubectl port-forward -n observability svc/kibana 5601:5601
# Access at http://localhost:5601

# Jaeger
kubectl port-forward -n observability svc/jaeger 16686:16686
# Access at http://localhost:16686
```

### Step 4: Test Service Deployment

```bash
# Deploy a test service
kc init test-service go-rest-api
cd test-service
kc deploy --env dev

# Check logs
kc logs test-service --tail 50 --follow

# Get metrics
kc metrics test-service

# View status
kc status test-service
```

---

## Troubleshooting

### Common Issues

#### EKS Cluster Not Connecting

```bash
# Verify security groups allow your IP
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=kubechamp-*"

# Update kubeconfig
aws eks update-kubeconfig --name kubechamp-dev --region us-east-1 --force

# Check IAM permissions
aws sts get-caller-identity
```

#### Pod Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check resource availability
kubectl describe nodes
```

#### Ingress Not Working

```bash
# Verify ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resources
kubectl get ingress -A

# Check service endpoints
kubectl get endpoints
```

---

## Operations Guide

### Scaling

```bash
# Scale a deployment
kubectl scale deployment <name> --replicas=5 -n <namespace>

# Auto-scaling with HPA
kubectl autoscale deployment <name> --min=2 --max=10 --cpu-percent=70
```

### Monitoring

```bash
# View cluster metrics
kubectl top nodes
kubectl top pods

# Get resource usage
kubectl describe node <node-name>
```

### Updates and Patches

```bash
# Update Helm chart
helm upgrade kubechamp-platform ./platform/helm-charts/platform-core -n platform

# Update image
kubectl set image deployment/<name> <container>=<image>:<tag>

# Rollout status
kubectl rollout status deployment/<name>
```

---

## Backup and Disaster Recovery

### Backup ETCD

```bash
# Create backup
kubectl exec -it -n kube-system etcd-master \
    -- etcdctl snapshot save /var/lib/etcd-backup.db
```

### Backup Helm Releases

```bash
# Export all releases
helm list -A -o json > helm-backup-$(date +%Y%m%d).json
```

---

## Security Checklist

- [ ] Enable encryption at rest for EBS volumes
- [ ] Configure security groups with principle of least privilege
- [ ] Enable audit logging in EKS
- [ ] Set up Pod Security Policies
- [ ] Configure Network Policies
- [ ] Enable RBAC
- [ ] Use Vault for secrets management
- [ ] Enable TLS for all communications
- [ ] Regular vulnerability scanning
- [ ] Set up monitoring and alerting

---

## Next Steps

1. Deploy your microservices using the CLI tool
2. Configure GitOps workflows in ArgoCD
3. Set up monitoring alerts
4. Implement security policies
5. Perform load testing
6. Document runbooks for operations team

For more information, see the main [README.md](../README.md)
