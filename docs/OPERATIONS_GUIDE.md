# KubeChamp Operations Guide

## Daily Operations

### Monitoring Health

```bash
# Check cluster status
kubectl cluster-info

# Check all nodes
kubectl get nodes -o wide

# Check pod status
kubectl get pods -A

# Get cluster metrics
kubectl top nodes
kubectl top pods -A

# Check resource availability
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Viewing Logs

```bash
# View central logs (Kibana)
kubectl port-forward -n observability svc/kibana 5601:5601
# Open http://localhost:5601

# View pod logs
kubectl logs <pod-name> -n <namespace>

# Follow logs in real-time
kubectl logs <pod-name> -n <namespace> -f

# View logs from all pods in deployment
kubectl logs -l app=<app-name> -n <namespace> --tail=100
```

### Accessing Dashboards

```bash
# Grafana (Dashboards)
kubectl port-forward -n observability svc/grafana 3000:80

# Prometheus (Metrics)
kubectl port-forward -n observability svc/prometheus 9090:9090

# Jaeger (Tracing)
kubectl port-forward -n observability svc/jaeger 16686:16686

# ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

---

## Scaling Operations

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment <name> --replicas=5 -n <namespace>

# Verify scaling
kubectl get deployment <name> -n <namespace>

# Watch rollout
kubectl rollout status deployment/<name> -n <namespace>
```

### Auto-Scaling Configuration

```bash
# Create HPA
kubectl autoscale deployment <name> \
    --min=2 --max=10 \
    --cpu-percent=70 \
    -n <namespace>

# View HPA status
kubectl get hpa -n <namespace>

# Update HPA
kubectl patch hpa <name> -p '{"spec":{"maxReplicas":20}}' -n <namespace>
```

---

## Upgrading & Patching

### Updating Platform Components

```bash
# Update Helm repositories
helm repo update

# Check for chart updates
helm list -A

# Upgrade chart
helm upgrade <release> <chart> \
    -f values.yaml \
    -n <namespace>

# Verify upgrade
helm status <release> -n <namespace>

# Rollback if needed
helm rollback <release> <revision> -n <namespace>
```

### Updating Node Groups

```bash
# Update AMI for nodes
# In Terraform:
node_ami = "ami-xxx"  # New AMI ID

# Replace nodes
terraform plan
terraform apply

# Monitor node replacement
watch kubectl get nodes -o wide
```

### Kubernetes Version Upgrade

```bash
# Update cluster version (managed)
# EKS handles control plane automatically

# Update node groups to match
terraform apply  # With new kubernetes_version

# Verify all nodes are up to date
kubectl get nodes -o wide | grep -c "1.27"
```

---

## Backup & Disaster Recovery

### Backup Procedures

```bash
# Backup Helm releases
helm list -A -o json > helm-backup-$(date +%Y%m%d).json

# Backup cluster config
kubectl get all -A -o yaml > cluster-backup-$(date +%Y%m%d).yaml

# Backup Terraform state
aws s3 cp $HOME/.terraform/state/ \
    s3://kubechamp-backups/state/$(date +%Y%m%d)/ \
    --recursive

# Backup RDS database
aws rds create-db-snapshot \
    --db-instance-identifier kubechamp-prod \
    --db-snapshot-identifier kubechamp-prod-backup-$(date +%Y%m%d)
```

### Recovery Procedures

```bash
# Restore from Helm backup
helm install <release> <chart> \
    --values backup-values.yaml

# Restore Kubernetes resources
kubectl apply -f cluster-backup.yaml

# Restore RDS database
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier kubechamp-prod-restored \
    --db-snapshot-identifier kubechamp-prod-backup-20240101
```

---

## Incident Response

### Service Down

```bash
# 1. Check service status
kubectl get pods -l app=<service> -A

# 2. View logs
kubectl logs -l app=<service> -A --tail=100

# 3. Check events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# 4. Check resource constraints
kubectl top nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# 5. Restart deployment
kubectl rollout restart deployment/<service> -n <namespace>

# 6. Monitor recovery
kubectl rollout status deployment/<service> -n <namespace>
```

### High Error Rate

```bash
# 1. Check alert details in AlertManager
kubectl port-forward -n observability svc/alertmanager 9093:9093

# 2. View metrics in Prometheus
kubectl port-forward -n observability svc/prometheus 9090:9090

# 3. View traces in Jaeger
kubectl port-forward -n observability svc/jaeger 16686:16686

# 4. Scale up service
kubectl scale deployment <service> --replicas=10 -n <namespace>

# 5. Monitor error rate
# Check Grafana dashboard
```

### Out of Memory

```bash
# 1. Check memory usage
kubectl top pods -A | sort -k3 -rn | head -10

# 2. Identify problematic pod
kubectl describe pod <pod-name> -n <namespace>

# 3. Update resource limits
kubectl set resources deployment <name> \
    --limits=memory=1Gi \
    --requests=memory=512Mi \
    -n <namespace>

# 4. Monitor memory after change
watch kubectl top pods -n <namespace>
```

### Database Connection Issues

```bash
# 1. Check RDS status
aws rds describe-db-instances \
    --db-instance-identifier kubechamp-prod

# 2. Check security groups
aws ec2 describe-security-groups \
    --filters Name=tag:Name,Values=*kubechamp*

# 3. Test connectivity from pod
kubectl exec <pod> -n <namespace> -- \
    mysql -h $DB_HOST -u $DB_USER -p -e "SELECT 1;"

# 4. Increase RDS connections if needed
aws rds modify-db-parameter-group \
    --db-parameter-group-name kubechamp-params \
    --parameters "ParameterName=max_connections,ParameterValue=1000"
```

---

## Performance Tuning

### Identifying Bottlenecks

```bash
# CPU bottleneck
kubectl top nodes | grep -v NAME | awk '{print $3}' | sort -rn | head -5

# Memory bottleneck
kubectl top pods -A | grep -v CONTAINER | sort -k3 -rn | head -10

# Network bottleneck
kubectl get nodes -o wide | grep -v STATUS
```

### Optimization Tips

```bash
# 1. Increase container resources
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 1000m
    memory: 1Gi

# 2. Enable HPA
kubectl autoscale deployment <name> --min=5 --max=20 --cpu-percent=60

# 3. Optimize database queries
# Review slow query log
# Add indexes
# Connection pooling

# 4. Enable caching
# Redis/Memcached sidecar
# Response caching in API Gateway
```

---

## Security Maintenance

### Regular Security Checks

```bash
# Check for security updates
kubectl get nodes -o json | jq '.items[].status.nodeInfo'

# Scan for vulnerable images
trivy image ghcr.io/kubechamp/service:latest

# Check RBAC permissions
kubectl get roles -A
kubectl get rolebindings -A

# Audit logging review
kubectl logs -n kube-system kubelet | grep audit
```

### Secret Rotation

```bash
# Update secret
kubectl create secret generic <name> \
    --from-literal=password=<new-password> \
    --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new secret
kubectl rollout restart deployment/<name> -n <namespace>

# Verify secret is updated
kubectl get secret <name> -o yaml
```

### Certificate Management

```bash
# Check certificate expiration
kubectl get certificate -A -o wide

# Renew certificate
kubectl delete certificate <cert-name> -n <namespace>
# cert-manager will recreate with new cert

# View certificate details
kubectl describe certificate <cert-name> -n <namespace>
```

---

## Cost Optimization

### Right-Sizing Instances

```bash
# Analyze usage patterns
kubectl describe nodes | grep -A 5 "Allocated resources"

# Identify underutilized nodes
kubectl top nodes

# Scale down overprovisioned deployments
kubectl set resources deployment <name> \
    --limits=cpu=500m,memory=512Mi \
    --requests=cpu=250m,memory=256Mi
```

### Scheduled Scaling

```bash
# Scale down for non-business hours
kubectl patch cronjob downscale \
    --patch='{"spec":{"schedule":"0 22 * * *"}}'

# Scale up for business hours
kubectl patch cronjob upscale \
    --patch='{"spec":{"schedule":"0 6 * * *"}}'
```

### Reserved Instances

```bash
# Purchase reserved instances for baseline load
# Use SPOT instances for flexible workloads
# Terraform configuration:

node_groups = {
  system = {
    capacity_type = "ON_DEMAND"
  }
  applications = {
    capacity_type = "SPOT"  # 70% cost savings
  }
}
```

---

## Runbook Examples

### Service Restart Runbook

```bash
#!/bin/bash
# Restart a service safely

SERVICE=$1
NAMESPACE=${2:-default}

echo "Restarting $SERVICE in $NAMESPACE..."

# 1. Get current replica count
REPLICAS=$(kubectl get deployment $SERVICE -n $NAMESPACE -o jsonpath='{.spec.replicas}')

# 2. Perform rolling restart
kubectl rollout restart deployment/$SERVICE -n $NAMESPACE

# 3. Wait for rollout
kubectl rollout status deployment/$SERVICE -n $NAMESPACE

# 4. Verify pods are healthy
kubectl get pods -l app=$SERVICE -n $NAMESPACE

echo "Restart complete!"
```

### Database Snapshot Runbook

```bash
#!/bin/bash
# Create automated database snapshot

DB_ID="kubechamp-prod"
BACKUP_ID="kubechamp-prod-backup-$(date +%Y%m%d-%H%M%S)"

echo "Creating backup: $BACKUP_ID"

aws rds create-db-snapshot \
    --db-instance-identifier $DB_ID \
    --db-snapshot-identifier $BACKUP_ID

echo "Backup started. ID: $BACKUP_ID"

# Wait for backup to complete
aws rds describe-db-snapshots \
    --db-snapshot-identifier $BACKUP_ID \
    --query 'DBSnapshots[0].Status'
```

---

## Maintenance Summary

| Task | Frequency | Time Required |
|------|-----------|---------------|
| Monitor cluster health | Daily | 15 min |
| Review logs and metrics | Daily | 30 min |
| Backup verification | Weekly | 1 hour |
| Security patching | As needed | 2-4 hours |
| Capacity planning | Monthly | 2 hours |
| Disaster recovery drill | Quarterly | 4 hours |
| Major upgrade | Quarterly | 8 hours |
| Full security audit | Annually | 16 hours |

---

## Escalation Procedures

### Level 1 - Self-Service

- Use KubeChamp CLI for service management
- Check dashboards for issue diagnosis
- Follow runbooks for common issues

### Level 2 - Platform Team

- Cluster scaling issues
- Network/security problems
- Database connection issues
- Contact: #kubechamp-platform Slack channel

### Level 3 - Vendor Support

- EKS cluster issues
- AWS infrastructure issues
- RDS database issues
- Contact: AWS Support

---

## Helpful Resources

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Helm Charts Documentation](https://helm.sh/docs/)
- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
