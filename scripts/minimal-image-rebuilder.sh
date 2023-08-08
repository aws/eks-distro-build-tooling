set -e
set -o pipefail
set -x

sed -ri 's/:\s(.+)$/: null/g' EKS_DISTRO_TAG_FILE.yaml
