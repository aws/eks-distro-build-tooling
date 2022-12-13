package cmd

import (
	"fmt"
	"log"
	"strings"
	"time"

	gogithub "github.com/google/go-github/v48/github"
	"github.com/spf13/cobra"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/constants"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/issueManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/logger"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/repoManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

const (
	// Flag Names
	backportVersionFlag = "backportVersions"
	requestedByFlag     = "requestedBy"
	toplevelIssueIdFlag = "toplevelIssueId"
)

type backportIssueOptions struct {
	backportVersions []string
	requestedBy      string
	toplevelIssueId  int
}

var bpOptions = &backportIssueOptions{}

func init() {
	backportCmd.AddCommand(backportIssueCmd)
	backportIssueCmd.Flags().IntVarP(&bpOptions.toplevelIssueId, toplevelIssueIdFlag, "i", 0, "Issue ID to be backported e.g. 254")
	backportIssueCmd.Flags().StringVarP(&bpOptions.requestedBy, requestedByFlag, "r", "", "github username of the requester")
	backportIssueCmd.Flags().StringSliceVarP(&bpOptions.backportVersions, backportVersionFlag, "b", nil, "to specify versions to backport use this flag. Multiple versions can be specified separated by commas. e.g. <ver>,<ver>,<ver>. If no option is supplied, default is to use MAINTAINED_EOL_VERSIONS file in eks-distro-build-tooling/golang/go")

	requiredFlags := []string{
		toplevelIssueIdFlag,
	}
	for _, flag := range requiredFlags {
		if err := backportIssueCmd.MarkFlagRequired(flag); err != nil {
			log.Fatalf("failed to mark flag %v as requred: %v", flag, err)
		}
	}
}

var backportIssueCmd = &cobra.Command{
	Use:   "issue",
	Short: "Opens backport issues for top level github issue",
	Long:  "Opens issues to backport top level issue to EKS-Distro supported versions of Golang",
	RunE: func(cmd *cobra.Command, args []string) error {
		label := []string{"golang", "security"}
		issueState := "open"

		retrier := retrier.New(time.Second*380, retrier.WithBackoffFactor(1.5), retrier.WithMaxRetries(15, time.Second*30))

		token, err := github.GetGithubToken()
		if err != nil {
			return fmt.Errorf("getting Github PAT from environment at variable %s: %v", github.PersonalAccessTokenEnvVar, err)
		}
		githubClient, err := github.NewClient(cmd.Context(), token)
		if err != nil {
			return fmt.Errorf("setting up Github client: %v", err)
		}

		if bpOptions.backportVersions == nil {
			// When no version(s) are included as args, the default is to backport to all EOL versions
			// tracked at eks-distro-build-tooling/golang/go/MAINTAINED_EOL_VERSIONS
			// set up Repo Content Creator handler
			repoManagerOpts := &repoManager.Opts{
				SourceOwner: constants.Aws,
				SourceRepo:  constants.EksdBuildTooling,
			}
			rm := repoManager.New(retrier, githubClient, repoManagerOpts)

			gfOpts := &repoManager.GetFileOpts{
				Owner: constants.Aws,
				Repo:  constants.EksdBuildTooling,
				Path:  constants.EksGoSupportedVersionsPath,
				Ref:   nil,
			}

			f, err := rm.GetFile(cmd.Context(), gfOpts)
			if err != nil {
				return fmt.Errorf("getting file at %s: %v", gfOpts.Path, err)
			}
			fc, err := f.GetContent()
			if err != nil {
				return fmt.Errorf("getting file content from %v: %v", f.Name, err)
			}

			bpOptions.backportVersions = strings.Split(fc, "\n")
		}

		// set up Issue Creator handler
		issueManagerOpts := &issueManager.Opts{
			SourceOwner: constants.Aws,
			SourceRepo:  constants.EksdBuildTooling,
		}
		im := issueManager.New(retrier, githubClient, issueManagerOpts)

		giOpts := &issueManager.GetIssueOpts{
			Owner: constants.Aws,
			Repo:  constants.EksdBuildTooling,
			Issue: bpOptions.toplevelIssueId,
		}

		toplevelIssue, err := im.GetIssue(cmd.Context(), giOpts)
		if err != nil {
			return fmt.Errorf("getting toplevel issue %v from %v: %v", giOpts.Issue, giOpts.Repo, err)
		}

		for _, ver := range bpOptions.backportVersions {
			if ver != "" {
				issueOpts := &issueManager.CreateIssueOpts{
					Title:    GenerateBackportIssueTitle(toplevelIssue, ver),
					Body:     GenerateBackportIssueBody(toplevelIssue, ver),
					Labels:   &label,
					Assignee: nil,
					State:    &issueState,
				}

				_, err := im.CreateIssue(cmd.Context(), issueOpts)
				if err != nil {
					return fmt.Errorf("creating issue: %v", err)
				}
			}
		}
		return nil
	},
}

func GenerateBackportIssueBody(ui *gogithub.Issue, ver string) *string {
	b := strings.Builder{}

	b.WriteString(fmt.Sprintf("A backport of issue %v to EKS Go %v was requested by @%v\n", *ui.HTMLURL, ver, bpOptions.requestedBy))
	b.WriteString(fmt.Sprintf("%v", *ui.Body))
	bs := b.String()
	logger.V(4).Info("Created Issues Body: `%s`\n", bs)
	return &bs
}

func GenerateBackportIssueTitle(ui *gogithub.Issue, ver string) *string {
	t := strings.Builder{}

	if *ui.Title != "" {
		t.WriteString(fmt.Sprintf("%v - [eks go%v backport]", *ui.Title, ver))
	}
	ts := t.String()

	logger.V(4).Info("Created Issues Title: `%s`\n", ts)
	return &ts
}
