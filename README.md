# litmus-demo

A minimal LitmusChaos pod-delete experiment against a k3s cluster.

Installs `litmus-core` (the chaos-operator alone — no ChaosCenter portal or
MongoDB), deploys a disposable 3-replica nginx target, kills ~50% of its
pods, waits for Kubernetes to reschedule them, and prints the verdict. Tears
itself down on exit.

## Run

```
./run.sh
```

Requires `kubectl` and `helm` pointed at a working cluster.

## Layout

- `manifests/00-namespace.yaml` — the `litmus-demo` namespace
- `manifests/01-nginx-target.yaml` — target deployment, 3 replicas
- `manifests/02-pod-delete-fault.yaml` — the `pod-delete` ChaosExperiment CR (from [litmuschaos/chaos-charts](https://github.com/litmuschaos/chaos-charts))
- `manifests/03-rbac.yaml` — ServiceAccount/Role/RoleBinding scoped to the fault's declared permissions
- `manifests/04-chaosengine.yaml` — the ChaosEngine that runs the fault against the target
- `demo.cast` — asciinema recording of a full run (`asciinema play demo.cast`)

## Notes

- On teardown, `run.sh` clears the ChaosEngine's finalizer before deleting
  the namespace — the finalizer expects the chaos-operator to remove it, and
  the operator is already gone by then (`helm uninstall` runs first), which
  otherwise stalls namespace deletion indefinitely.
