set -e
set -o pipefail
set -x

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

SED=sed
if [[ "$(uname -s)" == "Darwin" ]]; then
	SED=gsed
fi

$SED -ri 's/:\s(.+)$/: null/g' ${SCRIPT_ROOT}/../EKS_DISTRO_TAG_FILE.yaml
