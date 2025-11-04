# Template Helm para Deploy de Apps

Template Helm simples para deploy de aplicações customizadas no GKE.

## Dependências do Cluster

O cluster deve ter instalado:
- **Traefik** (ingress controller)
- **Cert Manager** (certificados SSL)
- **External Secrets** (gerenciamento de secrets)
- **Workload Identity** habilitado

## Tipos de Registry Suportados

### GHCR (GitHub Container Registry)
- Requer autenticação via external secrets
- Usa secret tipo `kubernetes.io/dockerconfigjson`

### Artifact Registry
- Usa workload identity para autenticação
- Não precisa de image pull secrets

### DockerHub
- Imagens públicas não precisam de autenticação
- Imagens privadas precisam de dockerconfigjson secret

## Configuração Básica

### Variáveis de Ambiente
Todas as variáveis em `env:` são automaticamente colocadas em um ConfigMap:

```yaml
env:
  NODE_ENV: production
  API_URL: https://api.exemplo.com
```

### Secrets
Referencia secrets existentes (nunca coloque valores de secrets no values.yaml):

```yaml
# Secrets completos como env vars
envFromSecrets:
  - database-credentials
  - api-keys

# Chaves específicas de secrets
envFromSecretKeys:
  - name: DATABASE_URL
    secretName: db-credentials
    key: url
```

### External Secrets (Simplificado)
```yaml
externalSecrets:
  enabled: true
  secretStore: gcp-secrets
  secrets:
    - name: ghcr-auth-secret
      key: ghcr-credentials
      type: dockerconfigjson
```

## Workload Identity

### 1. Criar Service Account no GCP
```bash
gcloud iam service-accounts create meu-app-sa \
  --project=seu-projeto
```

### 2. Configurar Workload Identity
```bash
gcloud iam service-accounts add-iam-policy-binding \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:seu-projeto.svc.id.goog[namespace/service-account-k8s]" \
  --project=seu-projeto \
  meu-app-sa@seu-projeto.iam.gserviceaccount.com
```

### 3. Configurar no values.yaml
```yaml
workloadIdentity:
  enabled: true
  serviceAccountName: meu-app-sa
  projectId: seu-projeto
```

**Importante**: Quando usar workload identity, não precisa configurar `GOOGLE_APPLICATION_CREDENTIALS`. As bibliotecas do Google Cloud detectam automaticamente.

## Scaling

### Replicas Fixas
```yaml
replicaCount: 3
```

### HPA (Horizontal Pod Autoscaler)
```yaml
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## Resource Limits
Sempre configure limites de recursos:

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 200m
    memory: 256Mi
```

## Exemplos

Veja a pasta `examples/` para configurações completas:
- `ghcr-example.yaml`: Deploy com GHCR e external secrets
- `artifact-registry-example.yaml`: Artifact Registry com workload identity
- `dockerhub-example.yaml`: Imagem pública do DockerHub
- `workload-identity-example.yaml`: Exemplo completo de workload identity
- `minimal-example.yaml`: Deploy mínimo
- `argocd-application.yaml`: Exemplo de Application do ArgoCD

## Deploy

### Com Helm
```bash
helm install meu-app https://github.com/retize-io/retize-chart.git//app -f values-production.yaml
```

### Com ArgoCD
Use o exemplo em `examples/argocd-application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  source:
    repoURL: https://github.com/retize-io/retize-chart.git
    path: app
    helm:
      valueFiles:
        - ../examples/ghcr-example.yaml
```

## Boas Práticas

1. **Nunca coloque secrets no values.yaml** - Use external secrets ou referencie secrets existentes
2. **Use workload identity** para serviços GCP ao invés de montar chaves de service account
3. **Separe config de secrets** - Use ConfigMap para dados não-sensíveis
4. **Configure resource limits** - Sempre defina CPU e memória
5. **Use tags específicas** - Evite tag `latest` em produção
