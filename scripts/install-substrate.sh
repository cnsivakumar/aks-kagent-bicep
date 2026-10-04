#!/usr/bin/env bash

set -euo pipefail

SUBSTRATE_VERSION="0.2.0-beta5"

echo "Installing Agent Substrate CRDs..."

helm upgrade --install substrate-crds \
  oci://ghcr.io/kagent-dev/substrate/helm/substrate-crds \
  --version ${SUBSTRATE_VERSION} \
  --namespace ate-system \
  --create-namespace \
  --wait

echo "Installing Agent Substrate..."

helm upgrade --install substrate \
  oci://ghcr.io/kagent-dev/substrate/helm/substrate \
  --version ${SUBSTRATE_VERSION} \
  --namespace ate-system \
  -f kagent/substrate-values.yaml

echo "Installing kubectl-ate..."

curl -fsSL -o kubectl-ate \
  "https://github.com/kagent-dev/substrate/releases/download/v${SUBSTRATE_VERSION}/kubectl-ate-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')"

chmod +x kubectl-ate

sudo mv kubectl-ate /usr/local/bin/

kubectl ate --help

echo "Creating CA pools..."

kubectl ate admin make-ca-pool \
  --ca-id=1 \
  --name=service-dns-ca-pool \
  --secret-namespace=podcertificate-controller-system

kubectl ate admin make-ca-pool \
  --ca-id=1 \
  --name=pod-identity-ca-pool \
  --secret-namespace=podcertificate-controller-system

echo "Creating actor identity pools..."

kubectl ate admin make-jwt-pool \
  --key-id=1 \
  --name=actor-id-jwt-pool \
  --secret-namespace=ate-system

kubectl ate admin make-ca-pool \
  --ca-id=1 \
  --name=actor-id-ca-pool \
  --secret-namespace=ate-system

echo "Creating egress CA pool..."

kubectl ate admin make-ca-pool \
  --ca-id=1 \
  --name=egress-mitm-ca-pool \
  --secret-namespace=ate-system \
  --key-type=ECDSAP256

echo "Creating actor identity CA secret..."

actor_id_ca_root="$(
  kubectl get secret actor-id-ca-pool \
    -n ate-system \
    -o jsonpath='{.data.pool}' |
    base64 --decode |
    jq -r '.CAs[0].RootCertificateDER' |
    base64 --decode |
    openssl x509 -inform der -outform pem
)"

kubectl create secret generic actor-id-ca-certs \
  -n ate-system \
  --from-literal=ca.crt="${actor_id_ca_root}" \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

echo "Creating authentication configuration..."

k8s_issuer="$(
  kubectl get --raw /.well-known/openid-configuration |
  jq -r .issuer
)"

kubectl create configmap ate-api-authentication \
  -n ate-system \
  --from-literal=authentication.yaml="actorIdentityJWTProvider: kubernetes
jwtProviders:
- name: kubernetes
  issuer: ${k8s_issuer}
  audiences: [api.ate-system.svc]
  certificateAuthorityFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  discoveryTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
" \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

echo "Restarting Agent Substrate..."

helm upgrade substrate \
  oci://ghcr.io/kagent-dev/substrate/helm/substrate \
  --version ${SUBSTRATE_VERSION} \
  --namespace ate-system \
  --reuse-values \
  --wait \
  --timeout 10m

echo "Agent Substrate installed."

kubectl get pods -n ate-system