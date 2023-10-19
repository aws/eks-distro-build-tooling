package github

type GitHubUser struct {
	user  string
	email string
	token string
}

func NewGitHubUser(user, email, token string) GitHubUser {
	return GitHubUser{
		user:  user,
		email: email,
		token: token,
	}
}

func (ghu GitHubUser) User() string {
	return ghu.user
}

func (ghu GitHubUser) Email() string {
	return ghu.email
}

func (ghu GitHubUser) Token() string {
	return ghu.token
}
