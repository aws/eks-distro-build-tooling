package eksGoRelease

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/go-git/go-git/v5/plumbing/transport/http"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/git"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/prManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

const (
	minorReleaseBranchFmt = "eks-%s"
	basePathFmt           = "%s/%s/%s"
	patchesPathFmt        = "%s/%s/patches/%s"
	rpmSourcePathFmt      = "%s/%s/rpmbuild/SOURCES/%s"
	specPathFmt           = "%s/%s/rpmbuild/SPECS/%s"
	readmeFmtPath         = "tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease/readmeFmt.txt"
	newReleaseFile        = "tools/eksDistroBuildToolingOpsTools/pkg/eksGoRelease/newRelease.txt"
	fedoraFile            = "fedora.go"
	gdbinitFile           = "golang-gdbinit"
	goSpecFile            = "golang.spec"
)

func createReleasePR(ctx context.Context, r *Release, gClient git.Client, dryrun bool, prm *prManager.PrCreator, prOpts *prManager.CreatePrOpts) error {
	if !dryrun {
		commitMsg := fmt.Sprintf(newMinorVersionCommitMsgFmt, r.GoMinorVersion())
		if err := gClient.Commit(commitMsg); err != nil {
			logger.Error(err, "git commit", "message", commitMsg)
			return err
		}

		// Push to forked repository
		if err := gClient.Push(ctx); err != nil {
			logger.Error(err, "git push")
			return err
		}

		prUrl, err := prm.CreatePr(ctx, prOpts)
		if err != nil {
			// This shouldn't be an breaking error at this point the PR is not open but the changes
			// have been pushed and can be created manually.
			logger.Error(err, "github client create pr failed. Create PR manually from github webclient", "create pr opts", prOpts)
			prUrl = ""
		}

		logger.V(3).Info("Update EKS Go Version", "EKS Go Version", r.EksGoReleaseVersion(), "PR", prUrl)
	}
	return nil
}

func generateReadme(readmeFmt string, r Release) string {
	/* Format generated for the readme follows:
	 *  ----------------------------------------
	 *  # EKS Golang <title>
	 *
	 *  Current Release: `<curRelease>`
	 *
	 *  Tracking Tag: `<trackTag>`
	 *
	 *  ### Artifacts:
	 *  |Arch|Artifact|sha|
	 *  |:---:|:---:|:---:|
	 *  |noarch|[%s](%s)|[%s](%s)|
	 *  |x86_64|[%s](%s)|[%s](%s)|
	 *  |aarch64|[%s](%s)|[%s](%s)|
	 *  |arm64.tar.gz|[%s](%s)|[%s](%s)|
	 *  |amd64.tar.gz|[%s](%s)|[%s](%s)|
	 *
	 *  ### ARM64 Builds
	 *  [![Build status](<armBuild>)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)
	 *
	 *  ### AMD64 Builds
	 *  [![Build status](<amdBuild>)](https://prow.eks.amazonaws.com/?repo=aws%2Feks-distro-build-tooling&type=postsubmit)
	 *
	 *  ### Patches
	 *  The patches in `./patches` include relevant utility fixes for go `<patch>`.
	 *
	 *  ### Spec
	 *  The RPM spec file in `./rpmbuild/SPECS` is sourced from the go <fSpec> SRPM available on Fedora, and modified to include the relevant patches and build the `go<sSpec>` source.
	 *
	 */
	eksGoArches := [...]string{"noarch", "x86_64", "aarch64", "arm64", "amd64"}
	artifactTable := ""
	for _, a := range eksGoArches {
		artifact, sha, url := r.EksGoArtifacts(a)
		artifactTable = artifactTable + fmt.Sprintf("|%s|[%s](%s)|[%s](%s)|\n", a, artifact, fmt.Sprintf("%s/%s", url, artifact), sha, fmt.Sprintf("%s/%s", url, sha))
	}

	fmt.Println(readmeFmt)
	title := r.GoMinorVersion()
	curRelease := r.ReleaseNumber()
	trackTag := r.GoFullVersion()
	armBuild := r.EksGoArmBuild()
	amdBuild := r.EksGoAmdBuild()
	patch := r.GoMinorVersion()
	fSpec := r.GoMinorVersion()
	sSpec := r.GoMinorVersion()
	return fmt.Sprintf(readmeFmt, title, curRelease, trackTag, artifactTable, armBuild, amdBuild, patch, fSpec, sSpec)
}

func updateGoSpecPatchVersion(fc *string, r Release) string {
	gpO := fmt.Sprintf("%%global go_patch %d", r.PatchVersion()-1)
	gpN := fmt.Sprintf("%%global go_patch %d", r.PatchVersion())

	return strings.Replace(*fc, gpO, gpN, 1)
}

func addPatchGoSpec(fc *string, r Release, patch string) string {
	return ""
}
