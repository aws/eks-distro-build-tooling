# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -o pipefail
set -x

echo "Running install.sh in $(pwd)"

yum install -y jq

KUBECTL_VERSION=v1.22.6
EKS_D_RELEASE_BRANCH=1-22
EKS_D_RELEASE_NUMBER=3
curl -sSL "https://distro.eks.amazonaws.com/kubernetes-${EKS_D_RELEASE_BRANCH}/releases/${EKS_D_RELEASE_NUMBER}/artifacts/kubernetes/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /bin/kubectl
chmod +x /bin/kubectl

CA_BUNDLE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)
cat /config/mutatingwebhook.yaml | sed -e "s|\${CA_BUNDLE}|${CA_BUNDLE}|g" | sed -e "s|\${WEBHOOK_NAME}|${WEBHOOK_NAME}|g" | sed -e "s|\${NAMESPACE}|${NAMESPACE}|g" | sed -e "s|\${MWC_NAME}|${MWC_NAME}|g" > mutatingwebhook.yaml
kubectl apply -f mutatingwebhook.yaml

# Loop for a total of 50 seconds to give time for webhook to create CertificateSigningRequest
# The default hook timeout is 300, but for fargate there is a sleep container before this is run, and with the boot time of fargate containers, we get closer to the timeout if we increase the loop count
for i in {1..10}; do
    # Make sure to have the NAMESPACE and WEBHOOK_NAME env var defined
    for c in $(kubectl get csr -o json | jq -r ".items[] | select(.spec.username==\"system:serviceaccount:$NAMESPACE:$WEBHOOK_NAME\" and .status=={}).metadata.name"); do
        kubectl certificate approve $c
    done
    sleep 5
done
