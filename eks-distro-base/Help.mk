


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
minimal-images-base-python-3.11: ## Build, export packages, validate and run tests for minimal variant `base-python-3.11`
minimal-images-base-python-3.12: ## Build, export packages, validate and run tests for minimal variant `base-python-3.12`
minimal-images-base-python-3.13: ## Build, export packages, validate and run tests for minimal variant `base-python-3.13`
minimal-images-base-python-3.14: ## Build, export packages, validate and run tests for minimal variant `base-python-3.14`
minimal-images-base-nodejs-24: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-24`
minimal-images-base-nodejs-26: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-26`
minimal-images-base-golang-compiler-1.26-base: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.26-base`
minimal-images-base-golang-compiler-1.26-yum: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.26-yum`
minimal-images-base-golang-compiler-1.26-gcc: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.26-gcc`
minimal-images-base-golang-compiler-1.27-base: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.27-base`
minimal-images-base-golang-compiler-1.27-yum: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.27-yum`
minimal-images-base-golang-compiler-1.27-gcc: ## Build, export packages, validate and run tests for minimal variant `base-golang-compiler-1.27-gcc`
minimal-images-base-nodejs-compiler-24-base: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-24-base`
minimal-images-base-nodejs-compiler-26-base: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-26-base`
minimal-images-base-nodejs-compiler-24-yum: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-24-yum`
minimal-images-base-nodejs-compiler-26-yum: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-26-yum`
minimal-images-base-nodejs-compiler-24-gcc: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-24-gcc`
minimal-images-base-nodejs-compiler-26-gcc: ## Build, export packages, validate and run tests for minimal variant `base-nodejs-compiler-26-gcc`
minimal-images-base-python-compiler-3.11-base: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.11-base`
minimal-images-base-python-compiler-3.12-base: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.12-base`
minimal-images-base-python-compiler-3.13-base: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.13-base`
minimal-images-base-python-compiler-3.14-base: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.14-base`
minimal-images-base-python-compiler-3.11-yum: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.11-yum`
minimal-images-base-python-compiler-3.12-yum: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.12-yum`
minimal-images-base-python-compiler-3.13-yum: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.13-yum`
minimal-images-base-python-compiler-3.14-yum: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.14-yum`
minimal-images-base-python-compiler-3.11-gcc: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.11-gcc`
minimal-images-base-python-compiler-3.12-gcc: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.12-gcc`
minimal-images-base-python-compiler-3.13-gcc: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.13-gcc`
minimal-images-base-python-compiler-3.14-gcc: ## Build, export packages, validate and run tests for minimal variant `base-python-compiler-3.14-gcc`

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
packages-export-minimal-images-base-python-3.11: ## Export packages for minimal variant `base-python-3.11`
packages-export-minimal-images-base-python-3.12: ## Export packages for minimal variant `base-python-3.12`
packages-export-minimal-images-base-python-3.13: ## Export packages for minimal variant `base-python-3.13`
packages-export-minimal-images-base-python-3.14: ## Export packages for minimal variant `base-python-3.14`
packages-export-minimal-images-base-nodejs-24: ## Export packages for minimal variant `base-nodejs-24`
packages-export-minimal-images-base-nodejs-26: ## Export packages for minimal variant `base-nodejs-26`
packages-export-minimal-images-base-golang-compiler-1.26-base: ## Export packages for minimal variant `base-golang-compiler-1.26-base`
packages-export-minimal-images-base-golang-compiler-1.26-yum: ## Export packages for minimal variant `base-golang-compiler-1.26-yum`
packages-export-minimal-images-base-golang-compiler-1.26-gcc: ## Export packages for minimal variant `base-golang-compiler-1.26-gcc`
packages-export-minimal-images-base-golang-compiler-1.27-base: ## Export packages for minimal variant `base-golang-compiler-1.27-base`
packages-export-minimal-images-base-golang-compiler-1.27-yum: ## Export packages for minimal variant `base-golang-compiler-1.27-yum`
packages-export-minimal-images-base-golang-compiler-1.27-gcc: ## Export packages for minimal variant `base-golang-compiler-1.27-gcc`
packages-export-minimal-images-base-nodejs-compiler-24-base: ## Export packages for minimal variant `base-nodejs-compiler-24-base`
packages-export-minimal-images-base-nodejs-compiler-26-base: ## Export packages for minimal variant `base-nodejs-compiler-26-base`
packages-export-minimal-images-base-nodejs-compiler-24-yum: ## Export packages for minimal variant `base-nodejs-compiler-24-yum`
packages-export-minimal-images-base-nodejs-compiler-26-yum: ## Export packages for minimal variant `base-nodejs-compiler-26-yum`
packages-export-minimal-images-base-nodejs-compiler-24-gcc: ## Export packages for minimal variant `base-nodejs-compiler-24-gcc`
packages-export-minimal-images-base-nodejs-compiler-26-gcc: ## Export packages for minimal variant `base-nodejs-compiler-26-gcc`
packages-export-minimal-images-base-python-compiler-3.11-base: ## Export packages for minimal variant `base-python-compiler-3.11-base`
packages-export-minimal-images-base-python-compiler-3.12-base: ## Export packages for minimal variant `base-python-compiler-3.12-base`
packages-export-minimal-images-base-python-compiler-3.13-base: ## Export packages for minimal variant `base-python-compiler-3.13-base`
packages-export-minimal-images-base-python-compiler-3.14-base: ## Export packages for minimal variant `base-python-compiler-3.14-base`
packages-export-minimal-images-base-python-compiler-3.11-yum: ## Export packages for minimal variant `base-python-compiler-3.11-yum`
packages-export-minimal-images-base-python-compiler-3.12-yum: ## Export packages for minimal variant `base-python-compiler-3.12-yum`
packages-export-minimal-images-base-python-compiler-3.13-yum: ## Export packages for minimal variant `base-python-compiler-3.13-yum`
packages-export-minimal-images-base-python-compiler-3.14-yum: ## Export packages for minimal variant `base-python-compiler-3.14-yum`
packages-export-minimal-images-base-python-compiler-3.11-gcc: ## Export packages for minimal variant `base-python-compiler-3.11-gcc`
packages-export-minimal-images-base-python-compiler-3.12-gcc: ## Export packages for minimal variant `base-python-compiler-3.12-gcc`
packages-export-minimal-images-base-python-compiler-3.13-gcc: ## Export packages for minimal variant `base-python-compiler-3.13-gcc`
packages-export-minimal-images-base-python-compiler-3.14-gcc: ## Export packages for minimal variant `base-python-compiler-3.14-gcc`

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
validate-minimal-images-base-python-3.11: ## Validate for minimal variant `base-python-3.11`
validate-minimal-images-base-python-3.12: ## Validate for minimal variant `base-python-3.12`
validate-minimal-images-base-python-3.13: ## Validate for minimal variant `base-python-3.13`
validate-minimal-images-base-python-3.14: ## Validate for minimal variant `base-python-3.14`
validate-minimal-images-base-nodejs-24: ## Validate for minimal variant `base-nodejs-24`
validate-minimal-images-base-nodejs-26: ## Validate for minimal variant `base-nodejs-26`
validate-minimal-images-base-golang-compiler-1.26-base: ## Validate for minimal variant `base-golang-compiler-1.26-base`
validate-minimal-images-base-golang-compiler-1.26-yum: ## Validate for minimal variant `base-golang-compiler-1.26-yum`
validate-minimal-images-base-golang-compiler-1.26-gcc: ## Validate for minimal variant `base-golang-compiler-1.26-gcc`
validate-minimal-images-base-golang-compiler-1.27-base: ## Validate for minimal variant `base-golang-compiler-1.27-base`
validate-minimal-images-base-golang-compiler-1.27-yum: ## Validate for minimal variant `base-golang-compiler-1.27-yum`
validate-minimal-images-base-golang-compiler-1.27-gcc: ## Validate for minimal variant `base-golang-compiler-1.27-gcc`
validate-minimal-images-base-nodejs-compiler-24-base: ## Validate for minimal variant `base-nodejs-compiler-24-base`
validate-minimal-images-base-nodejs-compiler-26-base: ## Validate for minimal variant `base-nodejs-compiler-26-base`
validate-minimal-images-base-nodejs-compiler-24-yum: ## Validate for minimal variant `base-nodejs-compiler-24-yum`
validate-minimal-images-base-nodejs-compiler-26-yum: ## Validate for minimal variant `base-nodejs-compiler-26-yum`
validate-minimal-images-base-nodejs-compiler-24-gcc: ## Validate for minimal variant `base-nodejs-compiler-24-gcc`
validate-minimal-images-base-nodejs-compiler-26-gcc: ## Validate for minimal variant `base-nodejs-compiler-26-gcc`
validate-minimal-images-base-python-compiler-3.11-base: ## Validate for minimal variant `base-python-compiler-3.11-base`
validate-minimal-images-base-python-compiler-3.12-base: ## Validate for minimal variant `base-python-compiler-3.12-base`
validate-minimal-images-base-python-compiler-3.13-base: ## Validate for minimal variant `base-python-compiler-3.13-base`
validate-minimal-images-base-python-compiler-3.14-base: ## Validate for minimal variant `base-python-compiler-3.14-base`
validate-minimal-images-base-python-compiler-3.11-yum: ## Validate for minimal variant `base-python-compiler-3.11-yum`
validate-minimal-images-base-python-compiler-3.12-yum: ## Validate for minimal variant `base-python-compiler-3.12-yum`
validate-minimal-images-base-python-compiler-3.13-yum: ## Validate for minimal variant `base-python-compiler-3.13-yum`
validate-minimal-images-base-python-compiler-3.14-yum: ## Validate for minimal variant `base-python-compiler-3.14-yum`
validate-minimal-images-base-python-compiler-3.11-gcc: ## Validate for minimal variant `base-python-compiler-3.11-gcc`
validate-minimal-images-base-python-compiler-3.12-gcc: ## Validate for minimal variant `base-python-compiler-3.12-gcc`
validate-minimal-images-base-python-compiler-3.13-gcc: ## Validate for minimal variant `base-python-compiler-3.13-gcc`
validate-minimal-images-base-python-compiler-3.14-gcc: ## Validate for minimal variant `base-python-compiler-3.14-gcc`

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
test-minimal-images-base-python-3.11: ## Run tests for minimal variant `base-python-3.11`
test-minimal-images-base-python-3.12: ## Run tests for minimal variant `base-python-3.12`
test-minimal-images-base-python-3.13: ## Run tests for minimal variant `base-python-3.13`
test-minimal-images-base-python-3.14: ## Run tests for minimal variant `base-python-3.14`
test-minimal-images-base-nodejs-24: ## Run tests for minimal variant `base-nodejs-24`
test-minimal-images-base-nodejs-26: ## Run tests for minimal variant `base-nodejs-26`
test-minimal-images-base-golang-compiler-1.26-base: ## Run tests for minimal variant `base-golang-compiler-1.26-base`
test-minimal-images-base-golang-compiler-1.26-yum: ## Run tests for minimal variant `base-golang-compiler-1.26-yum`
test-minimal-images-base-golang-compiler-1.26-gcc: ## Run tests for minimal variant `base-golang-compiler-1.26-gcc`
test-minimal-images-base-golang-compiler-1.27-base: ## Run tests for minimal variant `base-golang-compiler-1.27-base`
test-minimal-images-base-golang-compiler-1.27-yum: ## Run tests for minimal variant `base-golang-compiler-1.27-yum`
test-minimal-images-base-golang-compiler-1.27-gcc: ## Run tests for minimal variant `base-golang-compiler-1.27-gcc`
test-minimal-images-base-nodejs-compiler-24-base: ## Run tests for minimal variant `base-nodejs-compiler-24-base`
test-minimal-images-base-nodejs-compiler-26-base: ## Run tests for minimal variant `base-nodejs-compiler-26-base`
test-minimal-images-base-nodejs-compiler-24-yum: ## Run tests for minimal variant `base-nodejs-compiler-24-yum`
test-minimal-images-base-nodejs-compiler-26-yum: ## Run tests for minimal variant `base-nodejs-compiler-26-yum`
test-minimal-images-base-nodejs-compiler-24-gcc: ## Run tests for minimal variant `base-nodejs-compiler-24-gcc`
test-minimal-images-base-nodejs-compiler-26-gcc: ## Run tests for minimal variant `base-nodejs-compiler-26-gcc`
test-minimal-images-base-python-compiler-3.11-base: ## Run tests for minimal variant `base-python-compiler-3.11-base`
test-minimal-images-base-python-compiler-3.12-base: ## Run tests for minimal variant `base-python-compiler-3.12-base`
test-minimal-images-base-python-compiler-3.13-base: ## Run tests for minimal variant `base-python-compiler-3.13-base`
test-minimal-images-base-python-compiler-3.14-base: ## Run tests for minimal variant `base-python-compiler-3.14-base`
test-minimal-images-base-python-compiler-3.11-yum: ## Run tests for minimal variant `base-python-compiler-3.11-yum`
test-minimal-images-base-python-compiler-3.12-yum: ## Run tests for minimal variant `base-python-compiler-3.12-yum`
test-minimal-images-base-python-compiler-3.13-yum: ## Run tests for minimal variant `base-python-compiler-3.13-yum`
test-minimal-images-base-python-compiler-3.14-yum: ## Run tests for minimal variant `base-python-compiler-3.14-yum`
test-minimal-images-base-python-compiler-3.11-gcc: ## Run tests for minimal variant `base-python-compiler-3.11-gcc`
test-minimal-images-base-python-compiler-3.12-gcc: ## Run tests for minimal variant `base-python-compiler-3.12-gcc`
test-minimal-images-base-python-compiler-3.13-gcc: ## Run tests for minimal variant `base-python-compiler-3.13-gcc`
test-minimal-images-base-python-compiler-3.14-gcc: ## Run tests for minimal variant `base-python-compiler-3.14-gcc`

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
minimal-update-base-python-3.11: ## Run update logic for minimal variant `base-python-3.11`
minimal-update-base-python-3.12: ## Run update logic for minimal variant `base-python-3.12`
minimal-update-base-python-3.13: ## Run update logic for minimal variant `base-python-3.13`
minimal-update-base-python-3.14: ## Run update logic for minimal variant `base-python-3.14`
minimal-update-base-nodejs-24: ## Run update logic for minimal variant `base-nodejs-24`
minimal-update-base-nodejs-26: ## Run update logic for minimal variant `base-nodejs-26`
minimal-update-base-golang-compiler-1.26-base: ## Run update logic for minimal variant `base-golang-compiler-1.26-base`
minimal-update-base-golang-compiler-1.26-yum: ## Run update logic for minimal variant `base-golang-compiler-1.26-yum`
minimal-update-base-golang-compiler-1.26-gcc: ## Run update logic for minimal variant `base-golang-compiler-1.26-gcc`
minimal-update-base-golang-compiler-1.27-base: ## Run update logic for minimal variant `base-golang-compiler-1.27-base`
minimal-update-base-golang-compiler-1.27-yum: ## Run update logic for minimal variant `base-golang-compiler-1.27-yum`
minimal-update-base-golang-compiler-1.27-gcc: ## Run update logic for minimal variant `base-golang-compiler-1.27-gcc`
minimal-update-base-nodejs-compiler-24-base: ## Run update logic for minimal variant `base-nodejs-compiler-24-base`
minimal-update-base-nodejs-compiler-26-base: ## Run update logic for minimal variant `base-nodejs-compiler-26-base`
minimal-update-base-nodejs-compiler-24-yum: ## Run update logic for minimal variant `base-nodejs-compiler-24-yum`
minimal-update-base-nodejs-compiler-26-yum: ## Run update logic for minimal variant `base-nodejs-compiler-26-yum`
minimal-update-base-nodejs-compiler-24-gcc: ## Run update logic for minimal variant `base-nodejs-compiler-24-gcc`
minimal-update-base-nodejs-compiler-26-gcc: ## Run update logic for minimal variant `base-nodejs-compiler-26-gcc`
minimal-update-base-python-compiler-3.11-base: ## Run update logic for minimal variant `base-python-compiler-3.11-base`
minimal-update-base-python-compiler-3.12-base: ## Run update logic for minimal variant `base-python-compiler-3.12-base`
minimal-update-base-python-compiler-3.13-base: ## Run update logic for minimal variant `base-python-compiler-3.13-base`
minimal-update-base-python-compiler-3.14-base: ## Run update logic for minimal variant `base-python-compiler-3.14-base`
minimal-update-base-python-compiler-3.11-yum: ## Run update logic for minimal variant `base-python-compiler-3.11-yum`
minimal-update-base-python-compiler-3.12-yum: ## Run update logic for minimal variant `base-python-compiler-3.12-yum`
minimal-update-base-python-compiler-3.13-yum: ## Run update logic for minimal variant `base-python-compiler-3.13-yum`
minimal-update-base-python-compiler-3.14-yum: ## Run update logic for minimal variant `base-python-compiler-3.14-yum`
minimal-update-base-python-compiler-3.11-gcc: ## Run update logic for minimal variant `base-python-compiler-3.11-gcc`
minimal-update-base-python-compiler-3.12-gcc: ## Run update logic for minimal variant `base-python-compiler-3.12-gcc`
minimal-update-base-python-compiler-3.13-gcc: ## Run update logic for minimal variant `base-python-compiler-3.13-gcc`
minimal-update-base-python-compiler-3.14-gcc: ## Run update logic for minimal variant `base-python-compiler-3.14-gcc`

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
minimal-create-pr-base-python-3.11: ## Run create pr logic for minimal variant `base-python-3.11`
minimal-create-pr-base-python-3.12: ## Run create pr logic for minimal variant `base-python-3.12`
minimal-create-pr-base-python-3.13: ## Run create pr logic for minimal variant `base-python-3.13`
minimal-create-pr-base-python-3.14: ## Run create pr logic for minimal variant `base-python-3.14`
minimal-create-pr-base-nodejs-24: ## Run create pr logic for minimal variant `base-nodejs-24`
minimal-create-pr-base-nodejs-26: ## Run create pr logic for minimal variant `base-nodejs-26`
minimal-create-pr-base-golang-compiler-1.26-base: ## Run create pr logic for minimal variant `base-golang-compiler-1.26-base`
minimal-create-pr-base-golang-compiler-1.26-yum: ## Run create pr logic for minimal variant `base-golang-compiler-1.26-yum`
minimal-create-pr-base-golang-compiler-1.26-gcc: ## Run create pr logic for minimal variant `base-golang-compiler-1.26-gcc`
minimal-create-pr-base-golang-compiler-1.27-base: ## Run create pr logic for minimal variant `base-golang-compiler-1.27-base`
minimal-create-pr-base-golang-compiler-1.27-yum: ## Run create pr logic for minimal variant `base-golang-compiler-1.27-yum`
minimal-create-pr-base-golang-compiler-1.27-gcc: ## Run create pr logic for minimal variant `base-golang-compiler-1.27-gcc`
minimal-create-pr-base-nodejs-compiler-24-base: ## Run create pr logic for minimal variant `base-nodejs-compiler-24-base`
minimal-create-pr-base-nodejs-compiler-26-base: ## Run create pr logic for minimal variant `base-nodejs-compiler-26-base`
minimal-create-pr-base-nodejs-compiler-24-yum: ## Run create pr logic for minimal variant `base-nodejs-compiler-24-yum`
minimal-create-pr-base-nodejs-compiler-26-yum: ## Run create pr logic for minimal variant `base-nodejs-compiler-26-yum`
minimal-create-pr-base-nodejs-compiler-24-gcc: ## Run create pr logic for minimal variant `base-nodejs-compiler-24-gcc`
minimal-create-pr-base-nodejs-compiler-26-gcc: ## Run create pr logic for minimal variant `base-nodejs-compiler-26-gcc`
minimal-create-pr-base-python-compiler-3.11-base: ## Run create pr logic for minimal variant `base-python-compiler-3.11-base`
minimal-create-pr-base-python-compiler-3.12-base: ## Run create pr logic for minimal variant `base-python-compiler-3.12-base`
minimal-create-pr-base-python-compiler-3.13-base: ## Run create pr logic for minimal variant `base-python-compiler-3.13-base`
minimal-create-pr-base-python-compiler-3.14-base: ## Run create pr logic for minimal variant `base-python-compiler-3.14-base`
minimal-create-pr-base-python-compiler-3.11-yum: ## Run create pr logic for minimal variant `base-python-compiler-3.11-yum`
minimal-create-pr-base-python-compiler-3.12-yum: ## Run create pr logic for minimal variant `base-python-compiler-3.12-yum`
minimal-create-pr-base-python-compiler-3.13-yum: ## Run create pr logic for minimal variant `base-python-compiler-3.13-yum`
minimal-create-pr-base-python-compiler-3.14-yum: ## Run create pr logic for minimal variant `base-python-compiler-3.14-yum`
minimal-create-pr-base-python-compiler-3.11-gcc: ## Run create pr logic for minimal variant `base-python-compiler-3.11-gcc`
minimal-create-pr-base-python-compiler-3.12-gcc: ## Run create pr logic for minimal variant `base-python-compiler-3.12-gcc`
minimal-create-pr-base-python-compiler-3.13-gcc: ## Run create pr logic for minimal variant `base-python-compiler-3.13-gcc`
minimal-create-pr-base-python-compiler-3.14-gcc: ## Run create pr logic for minimal variant `base-python-compiler-3.14-gcc`

##@ Compiler Images Targets
golang-compiler-images: ## Build compiler images for all versions of golang
golang-1.26-compiler-images: ## Build compiler images for golang-1.26
golang-1.27-compiler-images: ## Build compiler images for golang-1.27
nodejs-compiler-images: ## Build compiler images for all versions of nodejs
nodejs-24-compiler-images: ## Build compiler images for nodejs-24
nodejs-26-compiler-images: ## Build compiler images for nodejs-26
python-compiler-images: ## Build compiler images for all versions of python
python-3.11-compiler-images: ## Build compiler images for python-3.11
python-3.12-compiler-images: ## Build compiler images for python-3.12
python-3.13-compiler-images: ## Build compiler images for python-3.13
python-3.14-compiler-images: ## Build compiler images for python-3.14

########### END GENERATED ###########################
