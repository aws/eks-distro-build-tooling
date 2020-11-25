#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source $SCRIPT_ROOT/lib.sh

FAILED=()

cd ${STABLE}
for d in */; do
    helm lint ${STABLE}/${d} || FAILED+=("${d}")
done

if [ "${#FAILED[@]}" -eq  0 ]; then
    echo "All charts passed linting!"
    exit 0
else
    echo "Helm:"
    for chart in "${FAILED[@]}"; do
        printf "%40s ❌\n" "$chart"
    done
fi
