


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
minimal-images-base-compiler-base: ## Build, export packages, validate and run tests for minimal variant `base-compiler-base`
minimal-images-base-compiler-yum: ## Build, export packages, validate and run tests for minimal variant `base-compiler-yum`
minimal-images-base-compiler-gcc: ## Build, export packages, validate and run tests for minimal variant `base-compiler-gcc`
minimal-images-base-python-3.9: ## Build, export packages, validate and run tests for minimal variant `base-python-3.9`
minimal-images-base-nodejs-16: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-16`
minimal-images-base-nodejs-compiler-16-base: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-16-base`
minimal-images-base-nodejs-compiler-16-yum: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-16-yum`
minimal-images-base-nodejs-compiler-16-gcc: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-16-gcc`
minimal-images-base-golang-compiler-1.15-base: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.15-base`
minimal-images-base-golang-compiler-1.16-base: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.16-base`
minimal-images-base-golang-compiler-1.17-base: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.17-base`
minimal-images-base-golang-compiler-1.18-base: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.18-base`
minimal-images-base-golang-compiler-1.19-base: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.19-base`
minimal-images-base-golang-compiler-1.15-yum: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.15-yum`
minimal-images-base-golang-compiler-1.16-yum: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.16-yum`
minimal-images-base-golang-compiler-1.17-yum: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.17-yum`
minimal-images-base-golang-compiler-1.18-yum: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.18-yum`
minimal-images-base-golang-compiler-1.19-yum: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.19-yum`
minimal-images-base-golang-compiler-1.15-gcc: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.15-gcc`
minimal-images-base-golang-compiler-1.16-gcc: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.16-gcc`
minimal-images-base-golang-compiler-1.17-gcc: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.17-gcc`
minimal-images-base-golang-compiler-1.18-gcc: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.18-gcc`
minimal-images-base-golang-compiler-1.19-gcc: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.19-gcc`

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
packages-export-minimal-images-base-compiler-base: ## Export packages for minimal variant `base-compiler-base`
packages-export-minimal-images-base-compiler-yum: ## Export packages for minimal variant `base-compiler-yum`
packages-export-minimal-images-base-compiler-gcc: ## Export packages for minimal variant `base-compiler-gcc`
packages-export-minimal-images-base-python-3.9: ## Export packages for minimal variant `base-python-3.9`
packages-export-minimal-images-base-nodejs-16: ## Export packages for minimal variant `base-nodejs-16`
packages-export-minimal-images-base-nodejs-compiler-16-base: ## Export packages for minimal variant `base-nodejs-compiler-16-base`
packages-export-minimal-images-base-nodejs-compiler-16-yum: ## Export packages for minimal variant `base-nodejs-compiler-16-yum`
packages-export-minimal-images-base-nodejs-compiler-16-gcc: ## Export packages for minimal variant `base-nodejs-compiler-16-gcc`
packages-export-minimal-images-base-golang-compiler-1.15-base: ## Export packages for minimal variant `base-golang-compiler-1.15-base`
packages-export-minimal-images-base-golang-compiler-1.16-base: ## Export packages for minimal variant `base-golang-compiler-1.16-base`
packages-export-minimal-images-base-golang-compiler-1.17-base: ## Export packages for minimal variant `base-golang-compiler-1.17-base`
packages-export-minimal-images-base-golang-compiler-1.18-base: ## Export packages for minimal variant `base-golang-compiler-1.18-base`
packages-export-minimal-images-base-golang-compiler-1.19-base: ## Export packages for minimal variant `base-golang-compiler-1.19-base`
packages-export-minimal-images-base-golang-compiler-1.15-yum: ## Export packages for minimal variant `base-golang-compiler-1.15-yum`
packages-export-minimal-images-base-golang-compiler-1.16-yum: ## Export packages for minimal variant `base-golang-compiler-1.16-yum`
packages-export-minimal-images-base-golang-compiler-1.17-yum: ## Export packages for minimal variant `base-golang-compiler-1.17-yum`
packages-export-minimal-images-base-golang-compiler-1.18-yum: ## Export packages for minimal variant `base-golang-compiler-1.18-yum`
packages-export-minimal-images-base-golang-compiler-1.19-yum: ## Export packages for minimal variant `base-golang-compiler-1.19-yum`
packages-export-minimal-images-base-golang-compiler-1.15-gcc: ## Export packages for minimal variant `base-golang-compiler-1.15-gcc`
packages-export-minimal-images-base-golang-compiler-1.16-gcc: ## Export packages for minimal variant `base-golang-compiler-1.16-gcc`
packages-export-minimal-images-base-golang-compiler-1.17-gcc: ## Export packages for minimal variant `base-golang-compiler-1.17-gcc`
packages-export-minimal-images-base-golang-compiler-1.18-gcc: ## Export packages for minimal variant `base-golang-compiler-1.18-gcc`
packages-export-minimal-images-base-golang-compiler-1.19-gcc: ## Export packages for minimal variant `base-golang-compiler-1.19-gcc`

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
validate-minimal-images-base-compiler-base: ## Validate for minimal variant `base-compiler-base`
validate-minimal-images-base-compiler-yum: ## Validate for minimal variant `base-compiler-yum`
validate-minimal-images-base-compiler-gcc: ## Validate for minimal variant `base-compiler-gcc`
validate-minimal-images-base-python-3.9: ## Validate for minimal variant `base-python-3.9`
validate-minimal-images-base-nodejs-16: ## Validate for minimal variant `base-nodejs-16`
validate-minimal-images-base-nodejs-compiler-16-base: ## Validate for minimal variant `base-nodejs-compiler-16-base`
validate-minimal-images-base-nodejs-compiler-16-yum: ## Validate for minimal variant `base-nodejs-compiler-16-yum`
validate-minimal-images-base-nodejs-compiler-16-gcc: ## Validate for minimal variant `base-nodejs-compiler-16-gcc`
validate-minimal-images-base-golang-compiler-1.15-base: ## Validate for minimal variant `base-golang-compiler-1.15-base`
validate-minimal-images-base-golang-compiler-1.16-base: ## Validate for minimal variant `base-golang-compiler-1.16-base`
validate-minimal-images-base-golang-compiler-1.17-base: ## Validate for minimal variant `base-golang-compiler-1.17-base`
validate-minimal-images-base-golang-compiler-1.18-base: ## Validate for minimal variant `base-golang-compiler-1.18-base`
validate-minimal-images-base-golang-compiler-1.19-base: ## Validate for minimal variant `base-golang-compiler-1.19-base`
validate-minimal-images-base-golang-compiler-1.15-yum: ## Validate for minimal variant `base-golang-compiler-1.15-yum`
validate-minimal-images-base-golang-compiler-1.16-yum: ## Validate for minimal variant `base-golang-compiler-1.16-yum`
validate-minimal-images-base-golang-compiler-1.17-yum: ## Validate for minimal variant `base-golang-compiler-1.17-yum`
validate-minimal-images-base-golang-compiler-1.18-yum: ## Validate for minimal variant `base-golang-compiler-1.18-yum`
validate-minimal-images-base-golang-compiler-1.19-yum: ## Validate for minimal variant `base-golang-compiler-1.19-yum`
validate-minimal-images-base-golang-compiler-1.15-gcc: ## Validate for minimal variant `base-golang-compiler-1.15-gcc`
validate-minimal-images-base-golang-compiler-1.16-gcc: ## Validate for minimal variant `base-golang-compiler-1.16-gcc`
validate-minimal-images-base-golang-compiler-1.17-gcc: ## Validate for minimal variant `base-golang-compiler-1.17-gcc`
validate-minimal-images-base-golang-compiler-1.18-gcc: ## Validate for minimal variant `base-golang-compiler-1.18-gcc`
validate-minimal-images-base-golang-compiler-1.19-gcc: ## Validate for minimal variant `base-golang-compiler-1.19-gcc`

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
test-minimal-images-base-compiler-base: ## Run tests for minimal variant `base-compiler-base`
test-minimal-images-base-compiler-yum: ## Run tests for minimal variant `base-compiler-yum`
test-minimal-images-base-compiler-gcc: ## Run tests for minimal variant `base-compiler-gcc`
test-minimal-images-base-python-3.9: ## Run tests for minimal variant `base-python-3.9`
test-minimal-images-base-nodejs-16: ## Run tests for minimal variant `base-nodejs-16`
test-minimal-images-base-nodejs-compiler-16-base: ## Run tests for minimal variant `base-nodejs-compiler-16-base`
test-minimal-images-base-nodejs-compiler-16-yum: ## Run tests for minimal variant `base-nodejs-compiler-16-yum`
test-minimal-images-base-nodejs-compiler-16-gcc: ## Run tests for minimal variant `base-nodejs-compiler-16-gcc`
test-minimal-images-base-golang-compiler-1.15-base: ## Run tests for minimal variant `base-golang-compiler-1.15-base`
test-minimal-images-base-golang-compiler-1.16-base: ## Run tests for minimal variant `base-golang-compiler-1.16-base`
test-minimal-images-base-golang-compiler-1.17-base: ## Run tests for minimal variant `base-golang-compiler-1.17-base`
test-minimal-images-base-golang-compiler-1.18-base: ## Run tests for minimal variant `base-golang-compiler-1.18-base`
test-minimal-images-base-golang-compiler-1.19-base: ## Run tests for minimal variant `base-golang-compiler-1.19-base`
test-minimal-images-base-golang-compiler-1.15-yum: ## Run tests for minimal variant `base-golang-compiler-1.15-yum`
test-minimal-images-base-golang-compiler-1.16-yum: ## Run tests for minimal variant `base-golang-compiler-1.16-yum`
test-minimal-images-base-golang-compiler-1.17-yum: ## Run tests for minimal variant `base-golang-compiler-1.17-yum`
test-minimal-images-base-golang-compiler-1.18-yum: ## Run tests for minimal variant `base-golang-compiler-1.18-yum`
test-minimal-images-base-golang-compiler-1.19-yum: ## Run tests for minimal variant `base-golang-compiler-1.19-yum`
test-minimal-images-base-golang-compiler-1.15-gcc: ## Run tests for minimal variant `base-golang-compiler-1.15-gcc`
test-minimal-images-base-golang-compiler-1.16-gcc: ## Run tests for minimal variant `base-golang-compiler-1.16-gcc`
test-minimal-images-base-golang-compiler-1.17-gcc: ## Run tests for minimal variant `base-golang-compiler-1.17-gcc`
test-minimal-images-base-golang-compiler-1.18-gcc: ## Run tests for minimal variant `base-golang-compiler-1.18-gcc`
test-minimal-images-base-golang-compiler-1.19-gcc: ## Run tests for minimal variant `base-golang-compiler-1.19-gcc`

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
minimal-update-base-compiler-base: ## Run update logic for minimal variant `base-compiler-base`
minimal-update-base-compiler-yum: ## Run update logic for minimal variant `base-compiler-yum`
minimal-update-base-compiler-gcc: ## Run update logic for minimal variant `base-compiler-gcc`
minimal-update-base-python-3.9: ## Run update logic for minimal variant `base-python-3.9`
minimal-update-base-nodejs-16: ## Run update logic for minimal variant `base-nodejs-16`
minimal-update-base-nodejs-compiler-16-base: ## Run update logic for minimal variant `base-nodejs-compiler-16-base`
minimal-update-base-nodejs-compiler-16-yum: ## Run update logic for minimal variant `base-nodejs-compiler-16-yum`
minimal-update-base-nodejs-compiler-16-gcc: ## Run update logic for minimal variant `base-nodejs-compiler-16-gcc`
minimal-update-base-golang-compiler-1.15-base: ## Run update logic for minimal variant `base-golang-compiler-1.15-base`
minimal-update-base-golang-compiler-1.16-base: ## Run update logic for minimal variant `base-golang-compiler-1.16-base`
minimal-update-base-golang-compiler-1.17-base: ## Run update logic for minimal variant `base-golang-compiler-1.17-base`
minimal-update-base-golang-compiler-1.18-base: ## Run update logic for minimal variant `base-golang-compiler-1.18-base`
minimal-update-base-golang-compiler-1.19-base: ## Run update logic for minimal variant `base-golang-compiler-1.19-base`
minimal-update-base-golang-compiler-1.15-yum: ## Run update logic for minimal variant `base-golang-compiler-1.15-yum`
minimal-update-base-golang-compiler-1.16-yum: ## Run update logic for minimal variant `base-golang-compiler-1.16-yum`
minimal-update-base-golang-compiler-1.17-yum: ## Run update logic for minimal variant `base-golang-compiler-1.17-yum`
minimal-update-base-golang-compiler-1.18-yum: ## Run update logic for minimal variant `base-golang-compiler-1.18-yum`
minimal-update-base-golang-compiler-1.19-yum: ## Run update logic for minimal variant `base-golang-compiler-1.19-yum`
minimal-update-base-golang-compiler-1.15-gcc: ## Run update logic for minimal variant `base-golang-compiler-1.15-gcc`
minimal-update-base-golang-compiler-1.16-gcc: ## Run update logic for minimal variant `base-golang-compiler-1.16-gcc`
minimal-update-base-golang-compiler-1.17-gcc: ## Run update logic for minimal variant `base-golang-compiler-1.17-gcc`
minimal-update-base-golang-compiler-1.18-gcc: ## Run update logic for minimal variant `base-golang-compiler-1.18-gcc`
minimal-update-base-golang-compiler-1.19-gcc: ## Run update logic for minimal variant `base-golang-compiler-1.19-gcc`

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
minimal-create-pr-base-compiler-base: ## Run create pr logic for minimal variant `base-compiler-base`
minimal-create-pr-base-compiler-yum: ## Run create pr logic for minimal variant `base-compiler-yum`
minimal-create-pr-base-compiler-gcc: ## Run create pr logic for minimal variant `base-compiler-gcc`
minimal-create-pr-base-python-3.9: ## Run create pr logic for minimal variant `base-python-3.9`
minimal-create-pr-base-nodejs-16: ## Run create pr logic for minimal variant `base-nodejs-16`
minimal-create-pr-base-nodejs-compiler-16-base: ## Run create pr logic for minimal variant `base-nodejs-compiler-16-base`
minimal-create-pr-base-nodejs-compiler-16-yum: ## Run create pr logic for minimal variant `base-nodejs-compiler-16-yum`
minimal-create-pr-base-nodejs-compiler-16-gcc: ## Run create pr logic for minimal variant `base-nodejs-compiler-16-gcc`
minimal-create-pr-base-golang-compiler-1.15-base: ## Run create pr logic for minimal variant `base-golang-compiler-1.15-base`
minimal-create-pr-base-golang-compiler-1.16-base: ## Run create pr logic for minimal variant `base-golang-compiler-1.16-base`
minimal-create-pr-base-golang-compiler-1.17-base: ## Run create pr logic for minimal variant `base-golang-compiler-1.17-base`
minimal-create-pr-base-golang-compiler-1.18-base: ## Run create pr logic for minimal variant `base-golang-compiler-1.18-base`
minimal-create-pr-base-golang-compiler-1.19-base: ## Run create pr logic for minimal variant `base-golang-compiler-1.19-base`
minimal-create-pr-base-golang-compiler-1.15-yum: ## Run create pr logic for minimal variant `base-golang-compiler-1.15-yum`
minimal-create-pr-base-golang-compiler-1.16-yum: ## Run create pr logic for minimal variant `base-golang-compiler-1.16-yum`
minimal-create-pr-base-golang-compiler-1.17-yum: ## Run create pr logic for minimal variant `base-golang-compiler-1.17-yum`
minimal-create-pr-base-golang-compiler-1.18-yum: ## Run create pr logic for minimal variant `base-golang-compiler-1.18-yum`
minimal-create-pr-base-golang-compiler-1.19-yum: ## Run create pr logic for minimal variant `base-golang-compiler-1.19-yum`
minimal-create-pr-base-golang-compiler-1.15-gcc: ## Run create pr logic for minimal variant `base-golang-compiler-1.15-gcc`
minimal-create-pr-base-golang-compiler-1.16-gcc: ## Run create pr logic for minimal variant `base-golang-compiler-1.16-gcc`
minimal-create-pr-base-golang-compiler-1.17-gcc: ## Run create pr logic for minimal variant `base-golang-compiler-1.17-gcc`
minimal-create-pr-base-golang-compiler-1.18-gcc: ## Run create pr logic for minimal variant `base-golang-compiler-1.18-gcc`
minimal-create-pr-base-golang-compiler-1.19-gcc: ## Run create pr logic for minimal variant `base-golang-compiler-1.19-gcc`

########### END GENERATED ###########################
