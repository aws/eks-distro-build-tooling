package github_test

import (
	"fmt"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/pkg/github"
)

const (
	TestPatValue = "abcdefghijklmnopqrstuvwxyz"
)

func TestGithubPATAccessFailsUnset(t *testing.T) {
	err := os.Unsetenv(github.PersonalAccessTokenEnvVar)
	if err != nil {
		t.Errorf("failed to unset Github PAT env var during test setup")
	}
	_, err = github.GetGithubToken()
	assert.Errorf(t, err, fmt.Sprintf("Github Token environment variable %s not set", github.PersonalAccessTokenEnvVar))
}

func TestGithubPATAccessFailsSetEmpty(t *testing.T) {
	err := os.Setenv(github.PersonalAccessTokenEnvVar, "")
	if err != nil {
		t.Errorf("failed to set Github PAT env var during test setup")
	}
	_, err = github.GetGithubToken()
	assert.Errorf(t, err, fmt.Sprintf("Github Token enviornment variable %s is empty", github.PersonalAccessTokenEnvVar))
}

func TestGithubPATAccessSuccess(t *testing.T) {
	err := os.Setenv(github.PersonalAccessTokenEnvVar, TestPatValue)
	if err != nil {
		t.Errorf("failed to set Github PAT env var during test setup")
	}
	token, err := github.GetGithubToken()
	assert.Nil(t, err)
	assert.NotNil(t, token)
	assert.EqualValues(t, token, TestPatValue)
}
