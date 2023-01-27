package upstreampicker

import (
	"fmt"
	"os/exec"
	"regexp"

	"k8s.io/test-infra/prow/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
)

func HandleGolangPatchRelease(ghc &github.Client, iss github.Issue) error {
	var golangVersionsRe = regexp.MustCompile(`(?m)(\d+.\d+.\d+)`)
	var issNumRe = regexp.MustCompile(`(#\d+)`)
	m := make(map[string]int)
	for _, version := range golangVersionsRe.FindAllString(iss.Title, -1) {
		query := fmt.Sprintf("repo:%s/%s milestone:Go%s label:Security", constants.Golang, constants.Go, version)
		milestoneIssues, err := *ghc.FindIssuesWithOrg(constants.Golang, query, "", false)
		if err != nil {
			return fmt.Errorf("Find Golang Milestone: %v", err)
		}
		for i := range milestoneIssues {
			for _, biMatch := range issNumRe.FindAllString(i.Body, -1) {
				if m[biMatch] == 0 {
					m[biMatch] = 1
				}
			}
			return nil
		}
	}

	ownerArg := fmt.Sprintf("-o %s", constants.Golang)
	repoArg := fmt.Sprintf("-r %s", constants.Go)

	return nil
}

func CopyUpstreamIssue(issNum int, owner string, repo string) error {
	ownerArg := fmt.Sprintf("-o %s", owner)
	repoArg := fmt.Sprintf("-r %s", repo)
	issNumArg := fmt.Sprintf("-i %s", issNum)

	upstreampickerCmd := exec.Command(constants.EksGoTool, ownerArg, repoArg, issNumArg)
	stdOut, err := upstreampickerCmd.Output()
	if err != nil {
		fmt.Errorf("calling command: %s %s %s %s", constants.EksGoTool, ownerArg, repoArg, issNumArg)
	}

	return nil
}
