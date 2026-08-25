#!/usr/bin/env bash
set -euo pipefail

NS=litmus-demo
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup() {
  echo
  echo "== Tearing down =="
  helm uninstall litmus -n "$NS" >/dev/null 2>&1 || true
  kubectl delete ns "$NS" --wait=false >/dev/null 2>&1 || true
  # the chaosengine finalizer can outlive its operator once the operator
  # deployment is gone, which stalls namespace deletion indefinitely
  kubectl patch chaosengine nginx-chaos -n "$NS" --type=merge \
    -p '{"metadata":{"finalizers":[]}}' >/dev/null 2>&1 || true
  kubectl wait --for=delete ns/"$NS" --timeout=60s >/dev/null 2>&1 || true
  echo "done."
}
trap cleanup EXIT

echo "== Installing litmus-core operator (no ChaosCenter/portal) =="
helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm/ >/dev/null 2>&1 || true
helm repo update >/dev/null
kubectl apply -f "$DIR/manifests/00-namespace.yaml"
helm install litmus litmuschaos/litmus-core --namespace "$NS"
kubectl -n "$NS" rollout status deploy/litmus --timeout=90s

echo
echo "== Deploying disposable nginx target (3 replicas) =="
kubectl apply -f "$DIR/manifests/01-nginx-target.yaml"
kubectl -n "$NS" rollout status deploy/nginx-target --timeout=60s

echo
echo "== Registering pod-delete fault + scoped RBAC =="
kubectl apply -n "$NS" -f "$DIR/manifests/02-pod-delete-fault.yaml"
kubectl apply -f "$DIR/manifests/03-rbac.yaml"

echo
echo "== Target pods before chaos =="
kubectl -n "$NS" get pods -l app=nginx-target

echo
echo "== Launching ChaosEngine: kill ~50% of nginx-target pods =="
kubectl apply -f "$DIR/manifests/04-chaosengine.yaml"

echo "waiting for chaosresult verdict..."
until v=$(kubectl -n "$NS" get chaosresult nginx-chaos-pod-delete \
    -o jsonpath='{.status.experimentStatus.verdict}' 2>/dev/null) \
    && [ -n "$v" ] && [ "$v" != "Awaited" ]; do
  sleep 3
done

echo
echo "== Target pods after chaos (note the new pod age) =="
kubectl -n "$NS" get pods -l app=nginx-target

echo
echo "== Verdict =="
kubectl -n "$NS" get chaosresult nginx-chaos-pod-delete \
  -o jsonpath='verdict: {.status.experimentStatus.verdict}, probeSuccess: {.status.experimentStatus.probeSuccessPercentage}%{"\n"}'
