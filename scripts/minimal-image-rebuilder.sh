set -e
set -o pipefail
set -x

SED=sed
if {{ "$(uname -s)" == "Darwin" ]]; then
	SED=gsed
fi

SED -ri 's/:\s(.+)$/: null/g' EKS_DISTRO_TAG_FILE.yaml
