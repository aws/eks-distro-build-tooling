package repoManager_test

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
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/repoManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

const (
	HttpOkStatusCode         = 200
	rateLimitingGetFileError = "rate limited while attempting to get github file"
)

var (
	TestRepoOwner   = "TestTesterson"
	TestRepo        = "TestRepo"
	TestFilePath    = "test/path/to/file"
	TestFileContent = "Test content: Hello there"
	FileName        = "File"
)

func expectedLabels() *[]string {
	return &[]string{"sup", "test"}
}

func TestRepoManagerGetFileSuccess(t *testing.T) {
	ctx := context.Background()
	rm := newTestRepoManager(t)
	opts := &repoManager.GetFileOpts{
		Owner: TestRepoOwner,
		Repo:  TestRepo,
		Path:  TestFilePath,
		Ref:   nil,
	}
	expectedFile := &gogithub.RepositoryContent{
		Name:    &FileName,
		Path:    &TestFilePath,
		Content: &TestFileContent,
	}
	expectedResponse := &gogithub.Response{
		Response: &http.Response{
			StatusCode: HttpOkStatusCode,
		},
	}
	rm.repoClient.EXPECT().GetContents(ctx, TestRepoOwner, TestRepo, TestFilePath, opts.Ref).Return(expectedFile, nil, expectedResponse, nil)
	_, err := rm.repoManager.GetFile(context.Background(), opts)
	if err != nil {
		t.Errorf("RepoManager.GetFile() error = %v, want nil", err)
	}
}

func TestRepoManagerGetFileRateLimitedFail(t *testing.T) {
	ctx := context.Background()
	rm := newTestRepoManager(t)
	opts := &repoManager.GetFileOpts{
		Owner: TestRepoOwner,
		Repo:  TestRepo,
		Path:  TestFilePath,
		Ref:   nil,
	}
	expectedFile := &gogithub.RepositoryContent{
		Name:    &FileName,
		Path:    &TestFilePath,
		Content: &TestFileContent,
	}
	rm.repoClient.EXPECT().GetContents(ctx, TestRepoOwner, TestRepo, TestFilePath, opts.Ref).Return(expectedFile, nil, rateLimitedResponseBody(), nil)
	_, err := rm.repoManager.GetFile(context.Background(), opts)
	if err != nil && !strings.Contains(err.Error(), rateLimitingGetFileError) {
		t.Errorf("RepoManager.GetFile() rate limiting exepcted error; error = %v, want %s", err, rateLimitingGetFileError)
	}
}

func givenRetrier() *retrier.Retrier {
	return retrier.NewWithMaxRetries(4, 1)
}

type testRepoManager struct {
	repoManager *repoManager.RepoContentManager
	repoClient  *githubMocks.MockRepoClient
}

func newTestRepoManager(t *testing.T) testRepoManager {
	mockCtrl := gomock.NewController(t)
	repoClient := githubMocks.NewMockRepoClient(mockCtrl)
	githubClient := &github.Client{
		Repositories: repoClient,
	}

	o := &repoManager.Opts{
		SourceOwner: TestRepoOwner,
		SourceRepo:  TestRepo,
	}

	return testRepoManager{
		repoClient:  repoClient,
		repoManager: repoManager.New(givenRetrier(), githubClient, o),
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
