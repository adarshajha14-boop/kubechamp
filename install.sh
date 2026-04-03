#!/bin/bash

##############################################################################
# KubeChamp Platform - Quick Install Script
# This script downloads and installs KubeChamp for quick evaluation
##############################################################################

set -euo pipefail

KUBECHAMP_VERSION="1.0.0"
INSTALL_DIR="${HOME}/.local/bin"
REPO_URL="https://github.com/kubechamp/platform"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}KubeChamp Platform Installation${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check prerequisites
check_prerequisites() {
    local missing=()
    
    for cmd in git kubectl helm terraform aws; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing[*]}${NC}"
        echo -e "${YELLOW}Please install the missing tools and run again${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites installed${NC}"
}

# Clone repository
clone_repo() {
    echo ""
    echo -e "${BLUE}Cloning KubeChamp repository...${NC}"
    
    if [ -d "kubechamp" ]; then
        echo -e "${YELLOW}Directory 'kubechamp' already exists${NC}"
        read -p "Continue (y/n)? " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
        rm -rf kubechamp
    fi
    
    git clone --depth 1 "$REPO_URL.git" kubechamp
    cd kubechamp
    echo -e "${GREEN}✓ Repository cloned${NC}"
}

# Install CLI tool
install_cli() {
    echo ""
    echo -e "${BLUE}Installing KubeChamp CLI...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    cp developer-tools/cli/kc "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/kc"
    
    # Add to PATH if not already
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo ""
        echo -e "${YELLOW}Add this to your ~/.bashrc or ~/.zshrc:${NC}"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\""
    fi
    
    echo -e "${GREEN}✓ CLI installed at $INSTALL_DIR/kc${NC}"
}

# Create initial configuration
create_config() {
    echo ""
    echo -e "${BLUE}Creating configuration...${NC}"
    
    mkdir -p ~/.config/kubechamp
    mkdir -p ~/.cache/kubechamp
    
    # Create default config
    cat > ~/.config/kubechamp/config.yaml << 'EOF'
# KubeChamp Configuration

# Default environment
default_env: dev

# AWS credentials (optional)
aws:
  region: us-east-1
  profile: default

# Kubernetes contexts
environments:
  dev:
    cluster: kubechamp-dev
    region: us-east-1
  sit:
    cluster: kubechamp-sit
    region: us-east-1
  prod:
    cluster: kubechamp-prod
    region: us-east-1

# Registry
registry:
  provider: ecr
  account_id: ACCOUNT_ID  # Update this
  region: us-east-1

# Logging
logging:
  level: info
  format: json

EOF
    
    echo -e "${GREEN}✓ Configuration created at ~/.config/kubechamp/config.yaml${NC}"
}

# Create deployment guide
create_quickstart() {
    echo ""
    echo -e "${BLUE}Creating quickstart guide...${NC}"
    
    cat > QUICKSTART.md << 'EOF'
# KubeChamp Quick Start

## 1. Deploy Infrastructure

```bash
cd infrastructure/terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## 2. Configure kubectl

```bash
aws eks update-kubeconfig --name kubechamp-dev --region us-east-1
kubectl cluster-info
```

## 3. Deploy Platform

```bash
helm repo add stable https://charts.helm.sh/stable
helm repo update

# Deploy platform core
helm install kubechamp-platform ./platform/helm-charts/platform-core \
    --namespace platform --create-namespace --wait

# Deploy observability
helm install observability ./platform/helm-charts/observability \
    --namespace observability --create-namespace --wait
```

## 4. Deploy Your First Service

```bash
kc init my-service go-rest-api
cd my-service
kc deploy --env dev
```

## 5. Access Dashboards

```bash
# Grafana
kubectl port-forward -n observability svc/grafana 3000:80
# http://localhost:3000 (admin/admin)

# Prometheus
kubectl port-forward -n observability svc/prometheus 9090:9090
# http://localhost:9090
```

For detailed instructions, see [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)
EOF
    
    echo -e "${GREEN}✓ Quickstart guide created${NC}"
}

# Summary
print_summary() {
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo ""
    echo "1. Update AWS account ID in ~/.config/kubechamp/config.yaml"
    echo ""
    echo "2. Deploy infrastructure:"
    echo "   cd kubechamp/infrastructure/terraform/environments/dev"
    echo "   terraform init && terraform apply"
    echo ""
    echo "3. Configure kubectl:"
    echo "   aws eks update-kubeconfig --name kubechamp-dev --region us-east-1"
    echo ""
    echo "4. Deploy platform:"
    echo "   cd kubechamp"
    echo "   helm install kubechamp-platform ./platform/helm-charts/platform-core..."
    echo ""
    echo "5. Create your first service:"
    echo "   kc init my-service go-rest-api"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo "  - Main README: kubechamp/README.md"
    echo "  - Deployment Guide: kubechamp/docs/DEPLOYMENT_GUIDE.md"
    echo "  - Developer Guide: kubechamp/docs/DEVELOPER_GUIDE.md"
    echo "  - Architecture: kubechamp/docs/ARCHITECTURE.md"
    echo "  - Operations: kubechamp/docs/OPERATIONS_GUIDE.md"
    echo ""
    echo -e "${BLUE}Get help:${NC}"
    echo "  - kc --help"
    echo "  - https://docs.kubechamp.io"
    echo "  - GitHub Issues: $REPO_URL/issues"
    echo ""
}

# Main
main() {
    check_prerequisites || exit 1
    clone_repo || exit 1
    install_cli
    create_config
    create_quickstart
    print_summary
}

main "$@"
