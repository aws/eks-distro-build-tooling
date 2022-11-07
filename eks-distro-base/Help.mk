


########### DO NOT EDIT #############################
# To update call: make add-generated-help-block
# This is added to help document dynamic targets and support shell autocompletion


##@ Main Minimal Targets
minimal-images-base: ## Build, export packages, validate and run tests for minimal variant `base`
minimal-images-base-nonroot: ## Build, export packages, validate and run tests for minimal variant `base-nonroot`
minimal-images-base-glibc: ## Build, export packages, validate and run tests for minimal variant `base-glibc`
minimal-images-base-iptables: ## Build, export packages, validate and run tests for minimal variant `base-iptables`
minimal-images-base-nsenter: ## Build, export packages, validate and run tests for minimal variant `base-nsenter`
minimal-images-base-docker-client: ## Build, export packages, validate and run tests for minimal variant `base-docker-client`
minimal-images-base-nginx: ## Build, export packages, validate and run tests for minimal variant `base-nginx`
minimal-images-base-csi-ebs: ## Build, export packages, validate and run tests for minimal variant `base-csi-ebs`
minimal-images-base-csi: ## Build, export packages, validate and run tests for minimal variant `base-csi`
minimal-images-base-kind: ## Build, export packages, validate and run tests for minimal variant `base-kind`
minimal-images-base-haproxy: ## Build, export packages, validate and run tests for minimal variant `base-haproxy`
minimal-images-base-git: ## Build, export packages, validate and run tests for minimal variant `base-git`
minimal-images-base-python-3.9: ## Build, export packages, validate and run tests for minimal variant `base-python-3.9`

##@ Package Export Minimal Targets
packages-export-minimal-images-base: ## Export packages for minimal variant `base`
packages-export-minimal-images-base-nonroot: ## Export packages for minimal variant `base-nonroot`
packages-export-minimal-images-base-glibc: ## Export packages for minimal variant `base-glibc`
packages-export-minimal-images-base-iptables: ## Export packages for minimal variant `base-iptables`
packages-export-minimal-images-base-nsenter: ## Export packages for minimal variant `base-nsenter`
packages-export-minimal-images-base-docker-client: ## Export packages for minimal variant `base-docker-client`
packages-export-minimal-images-base-nginx: ## Export packages for minimal variant `base-nginx`
packages-export-minimal-images-base-csi-ebs: ## Export packages for minimal variant `base-csi-ebs`
packages-export-minimal-images-base-csi: ## Export packages for minimal variant `base-csi`
packages-export-minimal-images-base-kind: ## Export packages for minimal variant `base-kind`
packages-export-minimal-images-base-haproxy: ## Export packages for minimal variant `base-haproxy`
packages-export-minimal-images-base-git: ## Export packages for minimal variant `base-git`
packages-export-minimal-images-base-python-3.9: ## Export packages for minimal variant `base-python-3.9`

##@ Validate Minimal Targets
validate-minimal-images-base: ## Validate for minimal variant `base`
validate-minimal-images-base-nonroot: ## Validate for minimal variant `base-nonroot`
validate-minimal-images-base-glibc: ## Validate for minimal variant `base-glibc`
validate-minimal-images-base-iptables: ## Validate for minimal variant `base-iptables`
validate-minimal-images-base-nsenter: ## Validate for minimal variant `base-nsenter`
validate-minimal-images-base-docker-client: ## Validate for minimal variant `base-docker-client`
validate-minimal-images-base-nginx: ## Validate for minimal variant `base-nginx`
validate-minimal-images-base-csi-ebs: ## Validate for minimal variant `base-csi-ebs`
validate-minimal-images-base-csi: ## Validate for minimal variant `base-csi`
validate-minimal-images-base-kind: ## Validate for minimal variant `base-kind`
validate-minimal-images-base-haproxy: ## Validate for minimal variant `base-haproxy`
validate-minimal-images-base-git: ## Validate for minimal variant `base-git`
validate-minimal-images-base-python-3.9: ## Validate for minimal variant `base-python-3.9`

##@ Test Minimal Targets
test-minimal-images-base: ## Run tests for minimal variant `base`
test-minimal-images-base-nonroot: ## Run tests for minimal variant `base-nonroot`
test-minimal-images-base-glibc: ## Run tests for minimal variant `base-glibc`
test-minimal-images-base-iptables: ## Run tests for minimal variant `base-iptables`
test-minimal-images-base-nsenter: ## Run tests for minimal variant `base-nsenter`
test-minimal-images-base-docker-client: ## Run tests for minimal variant `base-docker-client`
test-minimal-images-base-nginx: ## Run tests for minimal variant `base-nginx`
test-minimal-images-base-csi-ebs: ## Run tests for minimal variant `base-csi-ebs`
test-minimal-images-base-csi: ## Run tests for minimal variant `base-csi`
test-minimal-images-base-kind: ## Run tests for minimal variant `base-kind`
test-minimal-images-base-haproxy: ## Run tests for minimal variant `base-haproxy`
test-minimal-images-base-git: ## Run tests for minimal variant `base-git`
test-minimal-images-base-python-3.9: ## Run tests for minimal variant `base-python-3.9`

##@ Update Minimal Targets
minimal-update-base: ## Run update logic for minimal variant `base`
minimal-update-base-nonroot: ## Run update logic for minimal variant `base-nonroot`
minimal-update-base-glibc: ## Run update logic for minimal variant `base-glibc`
minimal-update-base-iptables: ## Run update logic for minimal variant `base-iptables`
minimal-update-base-nsenter: ## Run update logic for minimal variant `base-nsenter`
minimal-update-base-docker-client: ## Run update logic for minimal variant `base-docker-client`
minimal-update-base-nginx: ## Run update logic for minimal variant `base-nginx`
minimal-update-base-csi-ebs: ## Run update logic for minimal variant `base-csi-ebs`
minimal-update-base-csi: ## Run update logic for minimal variant `base-csi`
minimal-update-base-kind: ## Run update logic for minimal variant `base-kind`
minimal-update-base-haproxy: ## Run update logic for minimal variant `base-haproxy`
minimal-update-base-git: ## Run update logic for minimal variant `base-git`
minimal-update-base-python-3.9: ## Run update logic for minimal variant `base-python-3.9`

##@ Create PR Minimal Targets
minimal-create-pr-base: ## Run create pr logic for minimal variant `base`
minimal-create-pr-base-nonroot: ## Run create pr logic for minimal variant `base-nonroot`
minimal-create-pr-base-glibc: ## Run create pr logic for minimal variant `base-glibc`
minimal-create-pr-base-iptables: ## Run create pr logic for minimal variant `base-iptables`
minimal-create-pr-base-nsenter: ## Run create pr logic for minimal variant `base-nsenter`
minimal-create-pr-base-docker-client: ## Run create pr logic for minimal variant `base-docker-client`
minimal-create-pr-base-nginx: ## Run create pr logic for minimal variant `base-nginx`
minimal-create-pr-base-csi-ebs: ## Run create pr logic for minimal variant `base-csi-ebs`
minimal-create-pr-base-csi: ## Run create pr logic for minimal variant `base-csi`
minimal-create-pr-base-kind: ## Run create pr logic for minimal variant `base-kind`
minimal-create-pr-base-haproxy: ## Run create pr logic for minimal variant `base-haproxy`
minimal-create-pr-base-git: ## Run create pr logic for minimal variant `base-git`
minimal-create-pr-base-python-3.9: ## Run create pr logic for minimal variant `base-python-3.9`

########### END GENERATED ###########################
