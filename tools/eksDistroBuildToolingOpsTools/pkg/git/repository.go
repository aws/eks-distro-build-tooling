package git

import (
	"fmt"

	gogit "github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/config"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/go-git/go-git/v5/storage/memory"
)

func NewRepository(cloneUrl, branch string) (*Repository, error) {
	repo := &Repository{
		CloneUrl: cloneUrl,
		Branch:   branch,
	}
	err := repo.Clone()
	if err != nil {
		return nil, err
	}
	return repo, nil
}

type Repository struct {
	CloneUrl   string
	Branch     string
	repository *gogit.Repository
}

func (r *Repository) Clone() error {
	repo, err := gogit.Clone(memory.NewStorage(), nil, &gogit.CloneOptions{
		URL: r.CloneUrl,
	})
	if err != nil {
		return fmt.Errorf("cloning repo %s: %v", r.CloneUrl, err)
	}
	r.repository = repo
	return nil
}

func (r *Repository) AddRemote(remoteUrl string, remoteName string) error {
	remoteConfig := &config.RemoteConfig{
		Name:  remoteName,
		URLs:  []string{remoteUrl},
	}
	_, err := r.repository.CreateRemote(remoteConfig)
	if err != nil {
		return fmt.Errorf("creating remote %s: %v", remoteUrl, err)
	}
	return nil
}

func (r *Repository) Checkout(refName string, refType ReferenceType) error {
	worktree, err := r.repository.Worktree()
	if err != nil {
		return fmt.Errorf("getting worktree for ref %s: %v", refName, err)
	}

	err = worktree.Checkout(&gogit.CheckoutOptions{
		Branch: plumbing.ReferenceName(fmt.Sprintf("%s/%s", refType.ReferenceString(), refName)),
	})
	return nil
}