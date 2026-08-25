#!/usr/bin/env bash
# Scripted demo run for the bottom pane of screenrc.
# Not meant to be run standalone outside that layout (it calls
# `screen -X quit` at the end to stop the whole recording session, k9s
# pane included).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo " LitmusChaos pod-delete demo"
echo
echo " What you're about to see: litmus-core (chaos-operator only,"
echo " no ChaosCenter/portal), a disposable 3-replica nginx target,"
echo " then a ChaosEngine killing ~50% of its pods. Watch the k9s"
echo " pane above for pods terminating and Kubernetes rescheduling"
echo " replacements before the verdict prints below."
echo "============================================================"
sleep 3

"$DIR/run.sh"

echo
echo "### demo done -- teardown already ran above"
sleep 4

screen -X quit
