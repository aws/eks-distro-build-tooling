package cmd

import (
	"fmt"
	"log"
	"strings"
	"time"

	gogithub "github.com/google/go-github/v48/github"
	"github.com/spf13/cobra"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/issueManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/version"
)

var (
	// Flag Variables
	upstreamIssueId       int
	announcementSourceUrl string
	dryRun                bool

	createCveIssue = &cobra.Command{
		Use:   "createCveIssue [OPTIONS]",
		Short: "Create new top level CVE Issue",
		Long:  `Create a new top level CVE Issue in aws/eks-distro-build-tooling`,
		RunE: func(cmd *cobra.Command, args []string) error {

			label := []string{"golang", "security"}
			assignee := "rcrozean"
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
				SourceOwner: "rcrozean",
				SourceRepo:  "eks-distro-build-tooling",
			}
			im := issueManager.New(retrier, githubClient, issueManagerOpts)

			giOpts := &issueManager.GetIssueOpts{
				Owner: "golang",
				Repo:  "go",
				Issue: upstreamIssueId,
			}

			upstreamIssue, err := im.GetIssue(cmd.Context(), giOpts)
			if err != nil {
				return fmt.Errorf("getting upstream issue: %v", err)
			}

			issueOpts := &issueManager.CreateIssueOpts{
				Title:    GenerateIssueTitle(upstreamIssue),
				Body:     GenerateIssueBody(upstreamIssue),
				Labels:   &label,
				Assignee: &assignee,
				State:    &issueState,
			}

			if !dryRun {
				_, err := im.CreateIssue(cmd.Context(), issueOpts)
				if err != nil {
					return fmt.Errorf("creating issue: %v", err)
				}
			}
			return nil
		},
	}
)

func init() {
	rootCmd.AddCommand(createCveIssue)
	createCveIssue.Flags().StringVar(&cveId, cveIdFlag, "", "CVE ID")
	createCveIssue.Flags().IntVarP(&upstreamIssueId, upstreamIssueIdFlag, "i", 0, "Upstream Issue ID e.g. ")
	createCveIssue.Flags().StringVarP(&upstreamCommitHash, upstreamCommitHashFlag, "c", "", "Upstream Commit ID e.g. ")
	createCveIssue.Flags().StringVar(&announcementSourceUrl, "announcemenSourceUrl", "", "Announcement Source URL e.g. https://groups.google.com/g/golang-announce/c/-hjNw559_tE/m/KlGTfid5CAAJ")
	createCveIssue.Flags().BoolVar(&dryRun, "dry-run", true, "Output the results without opening github issues/prs")

	requiredFlags := []string{
		cveIdFlag,
		upstreamCommitHashFlag,
		upstreamIssueIdFlag,
	}
	for _, flag := range requiredFlags {
		if err := createCveIssue.MarkFlagRequired(flag); err != nil {
			log.Fatalf("failed to mark flag %v as requred: %v", flag, err)
		}
	}
}

func GenerateIssueBody(ui *gogithub.Issue) *string {
	b := strings.Builder{}

	if announcementSourceUrl != "" {
		b.WriteString(fmt.Sprintf("From [Goland Security Announcemnt](%s)", announcementSourceUrl))
	}

	b.WriteString(fmt.Sprintf("For additional information for %s, find the checkout the upstream issue %s and fix %s", cveId, *ui.HTMLURL, upstreamCommitHash))

	b.WriteString("\n\n")
	b.WriteString(fmt.Sprintf("\n%s: %s", issueAutocreatedTemplate, authorNameFlag))
	b.WriteString(fmt.Sprintf("\nTool Version: `%s`", version.Get().GitVersion))

	bs := b.String()
	if dryRun {
		fmt.Printf("Created Issues Body: `%s`\n", bs)
	}
	return &bs
}

func GenerateIssueTitle(ui *gogithub.Issue) *string {
	t := strings.Builder{}

	if *ui.Title != "" {
		t.WriteString(fmt.Sprintf("%v - %v", *ui.Title, cveId))
	}
	ts := t.String()

	if dryRun {
		fmt.Printf("Created Issues Title: `%s`\n", ts)
	}
	return &ts
}
