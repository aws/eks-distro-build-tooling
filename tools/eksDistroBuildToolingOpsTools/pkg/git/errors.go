package git

import "fmt"

type RepositoryDoesNotExistError struct {
	repository string
	owner      string
	Err        error
}

func (e *RepositoryDoesNotExistError) Error() string {
	return fmt.Sprintf("repository %s with owner %s not found: %s", e.repository, e.owner, e.Err)
}

type RepositoryIsEmptyError struct {
	Repository string
}

func (e *RepositoryIsEmptyError) Error() string {
	return fmt.Sprintf("repository %s is empty can cannot be cloned", e.Repository)
}

type RepositoryUpToDateError struct{}

func (e *RepositoryUpToDateError) Error() string {
	return "error pulling from repository: already up-to-date"
}

type RemoteBranchDoesNotExistError struct {
	Repository string
	Branch     string
}

func (e *RemoteBranchDoesNotExistError) Error() string {
	return fmt.Sprintf("error pulling from repository %s: remote branch %s does not exist", e.Repository, e.Branch)
}
