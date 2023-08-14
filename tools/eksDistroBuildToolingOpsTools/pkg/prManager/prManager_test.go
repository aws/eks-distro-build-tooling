package prManager_test

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/golang/mock/gomock"
	gogithub "github.com/google/go-github/v48/github"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
	githubMocks "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github/mocks"
	prmanager "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/prManager"
	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/retrier"
)

const (
	HttpOkStatusCode = 200
)

var baseBranchSha = "940a814c746924db2019139e3de9ca9f2d60c22d"
var parentCommitSha = "d060b1b4309627ddc7bc0bc08cbcbe1894690c7c"
var testNewCommitSha = "72d34fc14ed813e183cce5f0bda5c71e7f0d058e"
var treeRootSha = "f7c2fc2f4f811ab8e7246a7b5ceee40f9f77be0f"

var (
	testRepoOwner         = "TestTesterson"
	testRepo              = "testRepo"
	testCommitBranchRef   = "refs/heads/testCommitBranch"
	testBaseBranchRef     = "refs/heads/main"
	testCommitAuthor      = "Author McTesterson"
	testCommitAuthorEmail = "test@test.com"
	testCommitMessage     = "testing this out"
	testPrSubject         = "test pr"
	testPrbranch          = "testBranch"
	testPrDescription     = "testing testing 123"
	testDestFileGitPath   = "test.txt"
	testBaseBranch        = "main"
	testCommitBranch      = "testCommitBranch"
)

func TestPrManagerCreatePRSuccess(t *testing.T) {
	ctx := context.Background()
	pr := newTestPrManager(t)

	opts := &prmanager.CreatePrOpts{
		CommitBranch:    testCommitBranch,
		BaseBranch:      testBaseBranch,
		AuthorName:      testCommitAuthor,
		AuthorEmail:     testCommitAuthorEmail,
		CommitMessage:   testCommitMessage,
		PrSubject:       testPrSubject,
		PrBranch:        testPrbranch,
		PrDescription:   testPrDescription,
		DestFileGitPath: testDestFileGitPath,
		SourceFileBody:  nil,
	}

	initialGitTree := &gogithub.Tree{
		SHA:       &treeRootSha,
		Entries:   nil,
		Truncated: gogithub.Bool(false),
	}

	baseBranchRef := &gogithub.Reference{
		Object: &gogithub.GitObject{
			SHA: &baseBranchSha,
		},
		Ref: gogithub.String(testCommitBranchRef),
	}

	// getRef()
	pr.gitClient.EXPECT().GetRef(ctx, testRepoOwner, testRepo, testCommitBranchRef).Return(baseBranchRef, nil, nil)

	// getTree()
	pr.gitClient.EXPECT().CreateTree(ctx, testRepoOwner, testRepo, baseBranchSha, gomock.Any()).Return(initialGitTree, nil, nil)

	// pushCommit()
	pr.repoClient.EXPECT().GetCommit(ctx, testRepoOwner, testRepo, baseBranchSha, nil).Return(getCommitExpectedCommit(), nil, nil)
	pr.gitClient.EXPECT().CreateCommit(ctx, testRepoOwner, testRepo, gomock.Any()).Return(newCommit(), nil, nil)
	pr.gitClient.EXPECT().UpdateRef(ctx, testRepoOwner, testRepo, baseBranchRef, false).Return(nil, nil, nil)

	// createReop()
	createdPr := &gogithub.PullRequest{}
	createPrResponse := &gogithub.Response{
		Response: &http.Response{
			StatusCode: HttpOkStatusCode,
		},
	}

	pr.prClient.EXPECT().Create(ctx, testRepoOwner, testRepo, gomock.Any()).Return(createdPr, createPrResponse, nil)

	_, err := pr.prManager.CreatePr(ctx, opts)
	if err != nil {
		t.Errorf("PrManager.CreatePr() exepcted no error; error = %s, want nil", err)
	}
}

func TestPrManagerCreatePRSuccessAlternatePath(t *testing.T) {
	ctx := context.Background()
	pr := newTestPrManager(t)

	opts := &prmanager.CreatePrOpts{
		CommitBranch:    testCommitBranch,
		BaseBranch:      testBaseBranch,
		AuthorName:      testCommitAuthor,
		AuthorEmail:     testCommitAuthorEmail,
		CommitMessage:   testCommitMessage,
		PrSubject:       testPrSubject,
		PrBranch:        testPrbranch,
		PrDescription:   testPrDescription,
		DestFileGitPath: testDestFileGitPath,
		SourceFileBody:  nil,
	}

	initialGitTree := &gogithub.Tree{
		SHA:       &treeRootSha,
		Entries:   nil,
		Truncated: gogithub.Bool(false),
	}

	commitBranchRef := &gogithub.Reference{
		Object: &gogithub.GitObject{
			SHA: &baseBranchSha,
		},
		Ref: gogithub.String(testBaseBranchRef),
	}

	commitBranchPostCommitRef := &gogithub.Reference{
		Object: &gogithub.GitObject{
			SHA: &baseBranchSha,
		},
		Ref: gogithub.String(testCommitBranchRef),
	}

	baseBranchRef := &gogithub.Reference{
		Object: &gogithub.GitObject{
			SHA: &baseBranchSha,
		},
		Ref: gogithub.String(testCommitBranchRef),
	}

	newCommitRef := &gogithub.Reference{
		Object: &gogithub.GitObject{
			SHA: &testNewCommitSha,
		},
		Ref: gogithub.String(testCommitBranchRef),
	}

	newRef := &gogithub.Reference{
		Object: &gogithub.GitObject{
			SHA: commitBranchPostCommitRef.Object.SHA,
		},
		Ref: gogithub.String(testCommitBranchRef),
	}

	// getRef()
	pr.gitClient.EXPECT().GetRef(ctx, testRepoOwner, testRepo, testCommitBranchRef).Return(baseBranchRef, nil, errors.New("commit not found"))
	pr.gitClient.EXPECT().GetRef(ctx, testRepoOwner, testRepo, testBaseBranchRef).Return(commitBranchRef, nil, nil)
	pr.gitClient.EXPECT().CreateRef(ctx, testRepoOwner, testRepo, newRef).Return(commitBranchPostCommitRef, nil, nil)

	// getTree()
	pr.gitClient.EXPECT().CreateTree(ctx, testRepoOwner, testRepo, baseBranchSha, gomock.Any()).Return(initialGitTree, nil, nil)

	// pushCommit()
	pr.repoClient.EXPECT().GetCommit(ctx, testRepoOwner, testRepo, baseBranchSha, nil).Return(getCommitExpectedCommit(), nil, nil)
	pr.gitClient.EXPECT().CreateCommit(ctx, testRepoOwner, testRepo, gomock.Any()).Return(newCommit(), nil, nil)
	pr.gitClient.EXPECT().UpdateRef(ctx, testRepoOwner, testRepo, newCommitRef, false).Return(nil, nil, nil)

	// createReop()
	createdPr := &gogithub.PullRequest{}
	createPrResponse := &gogithub.Response{
		Response: &http.Response{
			StatusCode: HttpOkStatusCode,
		},
	}

	pr.prClient.EXPECT().Create(ctx, testRepoOwner, testRepo, gomock.Any()).Return(createdPr, createPrResponse, nil)

	_, err := pr.prManager.CreatePr(ctx, opts)
	if err != nil {
		t.Errorf("PrManager.CreatePr() exepcted no error; error = %s, want nil", err)
	}
}

func givenRetrier() *retrier.Retrier {
	return retrier.NewWithMaxRetries(4, 1)
}

type testPrManager struct {
	prManager  *prmanager.PrCreator
	prClient   *githubMocks.MockPullRequestClient
	gitClient  *githubMocks.MockGitClient
	repoClient *githubMocks.MockRepoClient
}

func newTestPrManager(t *testing.T) testPrManager {
	mockCtrl := gomock.NewController(t)
	prClient := githubMocks.NewMockPullRequestClient(mockCtrl)
	gitClient := githubMocks.NewMockGitClient(mockCtrl)
	repoClient := githubMocks.NewMockRepoClient(mockCtrl)
	githubClient := &github.Client{
		PullRequests: prClient,
		Git:          gitClient,
		Repositories: repoClient,
	}

	o := &prmanager.Opts{
		SourceOwner: testRepoOwner,
		SourceRepo:  testRepo,
		PrRepo:      testRepo,
		PrRepoOwner: testRepoOwner,
	}

	return testPrManager{
		prClient:   prClient,
		gitClient:  gitClient,
		repoClient: repoClient,
		prManager:  prmanager.New(givenRetrier(), githubClient, o),
	}
}

func getCommitExpectedCommit() *gogithub.RepositoryCommit {
	commit := &gogithub.Commit{
		Author:  commitAuthor(),
		Message: &testCommitMessage,
		Tree:    nil,
		Parents: []*gogithub.Commit{
			{
				SHA: &baseBranchSha,
			},
		},
	}

	return &gogithub.RepositoryCommit{
		SHA:    gogithub.String(parentCommitSha),
		Commit: commit,
	}
}

func commitAuthor() *gogithub.CommitAuthor {
	date := time.Now()
	return &gogithub.CommitAuthor{
		Date:  &date,
		Name:  &testCommitAuthor,
		Email: &testCommitAuthorEmail,
	}
}

func newCommit() *gogithub.Commit {
	return &gogithub.Commit{
		Author:  commitAuthor(),
		Message: &testCommitMessage,
		Tree:    nil,
		SHA:     gogithub.String(testNewCommitSha),
		Parents: []*gogithub.Commit{
			{
				SHA: &baseBranchSha,
			},
		},
	}
}
