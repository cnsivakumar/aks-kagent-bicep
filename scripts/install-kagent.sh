#!/usr/bin/env bash

set -euo pipefail

KAGENT_VERSION="1.0.0-alpha7"

echo "Installing kagent CRDs..."

helm upgrade --install kagent-crds \
  oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --version ${KAGENT_VERSION} \
  --namespace kagent \
  --create-namespace \
  --wait

echo "Creating Azure OpenAI secret..."

kubectl create secret generic azure-openai-api-key \
  --namespace kagent \
  --from-literal=api-key="${AZURE_OPENAI_API_KEY}" \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

echo "Installing kagent..."

helm upgrade --install kagent \
  oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --version ${KAGENT_VERSION} \
  --namespace kagent \
  --create-namespace \
  --timeout 15m \
  -f kagent/kagent-values.yaml

echo "Waiting for kagent controller..."

kubectl rollout status \
  deployment/kagent-controller \
  -n kagent \
  --timeout=600s

echo "Applying ModelConfig..."

kubectl apply \
  -f k8s/modelconfig.yaml

echo "Applying RBAC..."

kubectl apply \
  -f k8s/rbac.yaml

echo "Applying Agent..."

kubectl apply \
  -f k8s/agent.yaml

echo ""
echo "===================================="
echo "kagent deployment completed"
echo "===================================="

kubectl get pods -n kagent

echo ""
echo "WorkerPool:"
kubectl get workerpools -n kagent

echo ""
echo "ModelConfigs:"
kubectl get modelconfigs -n kagent

echo ""
echo "AgentTemplates:"
kubectl get agenttemplates -n kagent