# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
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

KUBECTL_VERSION=v1.18.9
curl -sSL "https://distro.eks.amazonaws.com/kubernetes-1-18/releases/1/artifacts/kubernetes/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /bin/kubectl
chmod +x /bin/kubectl

CA_BUNDLE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)
cat /config/mutatingwebhook.yaml | sed -e "s|\${CA_BUNDLE}|${CA_BUNDLE}|g" | sed -e "s|\${WEBHOOK_NAME}|${WEBHOOK_NAME}|g" | sed -e "s|\${NAMESPACE}|${NAMESPACE}|g" | sed -e "s|\${MWC_NAME}|${MWC_NAME}|g" > mutatingwebhook.yaml
kubectl apply -f mutatingwebhook.yaml

# Loop for a total of 100 seconds (default hook timeout is 300) to give time for webhook to create CertificateSigningRequest
for i in {1..20}; do
    # Make sure to have the NAMESPACE and WEBHOOK_NAME env var defined
    for c in $(kubectl get csr -o json | jq -r ".items[] | select(.spec.username==\"system:serviceaccount:$NAMESPACE:$WEBHOOK_NAME\" and .status=={}).metadata.name"); do
        kubectl certificate approve $c
    done
    sleep 5
done
