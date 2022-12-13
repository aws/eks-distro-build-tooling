package issueManager_test

import (
	"context"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/golang/mock/gomock"
	gogithub "github.com/google/go-github/v48/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	githubMocks "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github/mocks"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/issueManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

const (
	HttpOkStatusCode        = 200
	rateLimitingIssuesError = "rate limited while attempting to create github issues"
)

var (
	TestRepoOwner      = "TestTesterson"
	TestRepo           = "TestRepo"
	IssueTitle         = "Title"
	IssueBody          = "Body"
	IssueAssignee      = "Jeff"
	IssueState         = "Open"
	ReturnIssueHtmlUrl = "https://github.com/testrepo/issues/999"
	IssueNumber        = 999
)

func expectedLabels() *[]string {
	return &[]string{"sup", "test"}
}

func TestIssueManagerCreateIssueSuccess(t *testing.T) {
	ctx := context.Background()
	im := newTestIssueManager(t)
	opts := &issueManager.CreateIssueOpts{
		Title:    &IssueTitle,
		Body:     &IssueBody,
		Labels:   expectedLabels(),
		Assignee: &IssueAssignee,
		State:    &IssueState,
	}
	expectedIssue := &gogithub.IssueRequest{
		Title:    &IssueTitle,
		Body:     &IssueBody,
		Labels:   expectedLabels(),
		Assignee: &IssueAssignee,
		State:    &IssueState,
	}
	expectedReturnIssue := &gogithub.Issue{
		HTMLURL: &ReturnIssueHtmlUrl,
	}
	expectedResponse := &gogithub.Response{
		Response: &http.Response{
			StatusCode: HttpOkStatusCode,
		},
	}
	im.issuesClient.EXPECT().Create(ctx, TestRepoOwner, TestRepo, expectedIssue).Return(expectedReturnIssue, expectedResponse, nil)
	_, err := im.issueManager.CreateIssue(context.Background(), opts)
	if err != nil {
		t.Errorf("IssueManager.CreateIssue() error = %v, want nil", err)
	}
}

func TestIssueManagerCreateIssueRateLimitedFail(t *testing.T) {
	ctx := context.Background()
	im := newTestIssueManager(t)
	opts := &issueManager.CreateIssueOpts{
		Title:    &IssueTitle,
		Body:     &IssueBody,
		Labels:   expectedLabels(),
		Assignee: &IssueAssignee,
		State:    &IssueState,
	}
	expectedIssue := &gogithub.IssueRequest{
		Title:    &IssueTitle,
		Body:     &IssueBody,
		Labels:   expectedLabels(),
		Assignee: &IssueAssignee,
		State:    &IssueState,
	}
	expectedReturnIssue := &gogithub.Issue{
		HTMLURL: &ReturnIssueHtmlUrl,
	}
	im.issuesClient.EXPECT().Create(ctx, TestRepoOwner, TestRepo, expectedIssue).Return(expectedReturnIssue, rateLimitedResponseBody(), nil)
	_, err := im.issueManager.CreateIssue(context.Background(), opts)
	if err != nil && !strings.Contains(err.Error(), rateLimitingIssuesError) {
		t.Errorf("IssueManager.CreateIssue() rate limiting exepcted error; error = nil, want %s", rateLimitingIssuesError)
	}
}

func TestIssueManagerGetIssueSuccess(t *testing.T) {
	ctx := context.Background()
	im := newTestIssueManager(t)
	opts := &issueManager.GetIssueOpts{
		Owner: TestRepoOwner,
		Repo:  TestRepo,
		Issue: IssueNumber,
	}
	expectedReturnIssue := &gogithub.Issue{
		HTMLURL: &ReturnIssueHtmlUrl,
	}
	expectedResponse := &gogithub.Response{
		Response: &http.Response{
			StatusCode: HttpOkStatusCode,
		},
	}
	im.issuesClient.EXPECT().Get(ctx, TestRepoOwner, TestRepo, IssueNumber).Return(expectedReturnIssue, expectedResponse, nil)
	_, err := im.issueManager.GetIssue(context.Background(), opts)
	if err != nil {
		t.Errorf("IssueManager.GetIssue() error = %v, want nil", err)
	}
}

func givenRetrier() *retrier.Retrier {
	return retrier.NewWithMaxRetries(4, 1)
}

type testIssueManager struct {
	issueManager *issueManager.IssueManager
	issuesClient *githubMocks.MockIssueClient
}

func newTestIssueManager(t *testing.T) testIssueManager {
	mockCtrl := gomock.NewController(t)
	issueClient := githubMocks.NewMockIssueClient(mockCtrl)
	githubClient := &github.Client{
		Issues: issueClient,
	}

	o := &issueManager.Opts{
		SourceOwner: TestRepoOwner,
		SourceRepo:  TestRepo,
	}

	return testIssueManager{
		issuesClient: issueClient,
		issueManager: issueManager.New(givenRetrier(), githubClient, o),
	}
}

func rateLimitedResponseBody() *gogithub.Response {
	rateLimitResponseBody := io.NopCloser(strings.NewReader(github.SecondaryRateLimitResponse))
	return &gogithub.Response{
		Response: &http.Response{
			StatusCode: github.SecondaryRateLimitStatusCode,
			Body:       rateLimitResponseBody,
		},
	}
}
