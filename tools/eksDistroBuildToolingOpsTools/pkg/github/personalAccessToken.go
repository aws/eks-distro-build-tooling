package github

import (
	"fmt"
	"os"
)

const (
	PersonalAccessTokenEnvVar = "GITHUB_TOKEN"
)

func GetGithubToken() (string, error){
	t, ok := os.LookupEnv(PersonalAccessTokenEnvVar); if !ok {
		return "", fmt.Errorf("Github Token environment variable %s not set", PersonalAccessTokenEnvVar)
	}
	if t == "" {
		return "", fmt.Errorf("Github Token enviornment variable %s is empty", PersonalAccessTokenEnvVar)
	}
	return t, nil
}