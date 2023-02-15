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
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

const (
	cveIdFlag                 = "cveId"
	upstreamIssueIdFlag       = "upstreamIssueId"
	upstreamCommitHashFlag    = "upstreamCommitHash"
	announcementSourceUrlFlag = "announcementSourceUrl"
)

type createToplevelIssueOptions struct {
	announcementSourceUrl string
	cveId                 string
	upstreamCommitHash    string
	upstreamIssueId       int
}

var ctiOpts = &createToplevelIssueOptions{}

func init() {
	rootCmd.AddCommand(createCveIssue)
	createCveIssue.Flags().StringVarP(&ctiOpts.cveId, cveIdFlag, "c", "", "CVE ID")
	createCveIssue.Flags().IntVarP(&ctiOpts.upstreamIssueId, upstreamIssueIdFlag, "i", 0, "Upstream Issue ID e.g. 56350")
	createCveIssue.Flags().StringVarP(&ctiOpts.upstreamCommitHash, upstreamCommitHashFlag, "u", "", "Upstream Commit Hash e.g. 76cad4edc29d28432a7a0aa27e87385d3d7db7a1")
	createCveIssue.Flags().StringVarP(&ctiOpts.announcementSourceUrl, announcementSourceUrlFlag, "a", "", "Announcement Source URL e.g. https://groups.google.com/g/golang-announce/c/-hjNw559_tE/m/KlGTfid5CAAJ")

	requiredFlags := []string{
		cveIdFlag,
		upstreamIssueIdFlag,
	}
	for _, flag := range requiredFlags {
		if err := createCveIssue.MarkFlagRequired(flag); err != nil {
			log.Fatalf("failed to mark flag %v as requred: %v", flag, err)
		}
	}
}

var createCveIssue = &cobra.Command{
	Use:   "createCveIssue [OPTIONS]",
	Short: "Create new top level CVE Issue",
	Long:  "Create a new top level CVE Issue in aws/eks-distro-build-tooling",
	RunE: func(cmd *cobra.Command, args []string) error {
		cveLabels := []string{"golang", "security"}
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

		// set up Issue Creator handler
		issueManagerOpts := &issueManager.Opts{
			SourceOwner: constants.AwsOrgName,
			SourceRepo:  constants.EksdBuildToolingRepoName,
		}
		im := issueManager.New(retrier, githubClient, issueManagerOpts)

		giOpts := &issueManager.GetIssueOpts{
			Owner: "golang",
			Repo:  "go",
			Issue: ctiOpts.upstreamIssueId,
		}

		upstreamIssue, err := im.GetIssue(cmd.Context(), giOpts)
		if err != nil {
			return fmt.Errorf("getting upstream issue: %v", err)
		}

		issueOpts := &issueManager.CreateIssueOpts{
			Title:    GenerateIssueTitle(upstreamIssue),
			Body:     GenerateIssueBody(upstreamIssue),
			Labels:   &cveLabels,
			Assignee: nil,
			State:    &issueState,
		}

		_, err = im.CreateIssue(cmd.Context(), issueOpts)
		if err != nil {
			return fmt.Errorf("creating issue: %v", err)
		}
		return nil
	},
}

func GenerateIssueBody(ui *gogithub.Issue) *string {
	b := strings.Builder{}

	if ctiOpts.announcementSourceUrl != "" {
		b.WriteString(fmt.Sprintf("From [Goland Security Announcemnt](%s),\n", ctiOpts.announcementSourceUrl))
	}

	b.WriteString(fmt.Sprintf("For additional information for %s, go to the upstream issue %s", ctiOpts.cveId, *ui.HTMLURL))

	if ctiOpts.upstreamCommitHash != "" {
		b.WriteString(fmt.Sprintf(" and fix commit https://github.com/golang/go/commit/%s", ctiOpts.upstreamCommitHash))
	}

	bs := b.String()
	logger.V(4).Info("Created Issues Body: `%s`\n", bs)
	return &bs
}

func GenerateIssueTitle(ui *gogithub.Issue) *string {
	t := strings.Builder{}

	if *ui.Title != "" {
		t.WriteString(fmt.Sprintf("%v", *ui.Title))
	}
	ts := t.String()
	logger.V(4).Info("Created Issues Title: `%s`\n", ts)
	return &ts
}
