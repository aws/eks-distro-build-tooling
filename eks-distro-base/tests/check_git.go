// Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Modeled from https://gist.github.com/zchee/444c8c20aa7756468d8e

package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	git "github.com/libgit2/git2go/v31"
)

func credentialsMemoryCallback(url string, username string, allowedTypes git.CredType) (*git.Credential, error) {
	pub, err := ioutil.ReadFile("/root/.ssh/id_rsa.pub")
	if err != nil {
		log.Fatalf("unable to read file: %v", err)
	}
	pri, err := ioutil.ReadFile("/root/.ssh/id_rsa")
	if err != nil {
		log.Fatalf("unable to read file: %v", err)
	}
	cred, err := git.NewCredentialSSHKeyFromMemory("git", string(pub), string(pri), "")
	if err != nil {
		return nil, err
	}
	return cred, nil

}

func credentialsFileCallback(url string, username string, allowedTypes git.CredType) (*git.Credential, error) {
	cred, err := git.NewCredSshKey("git", "/root/.ssh/id_rsa.pub", "/root/.ssh/id_rsa", "")
	if err != nil {
		return nil, err
	}
	return cred, nil

}

// Made this one just return 0 during troubleshooting...
func certificateCheckCallback(cert *git.Certificate, valid bool, hostname string) git.ErrorCode {
	return 0
}

func main() {
	cloneOptions := &git.CloneOptions{
		FetchOptions: &git.FetchOptions{
			RemoteCallbacks: git.RemoteCallbacks{
				CredentialsCallback:      credentialsMemoryCallback,
				CertificateCheckCallback: certificateCheckCallback,
			},
		},
		CheckoutBranch: "main",
	}
	_, err := git.Clone(os.Getenv("PRIVATE_REPO"), "private-repo-memory", cloneOptions)
	if err != nil {
		log.Panic(err)
	}
	if _, err := os.Stat("private-repo-memory"); os.IsNotExist(err) {
		log.Panic("repo did not clone!")
	}

	cloneOptions = &git.CloneOptions{
		FetchOptions: &git.FetchOptions{
			RemoteCallbacks: git.RemoteCallbacks{
				CredentialsCallback:      credentialsFileCallback,
				CertificateCheckCallback: certificateCheckCallback,
			},
		},
		CheckoutBranch: "main",
	}
	_, err = git.Clone(os.Getenv("PRIVATE_REPO"), "private-repo-file", cloneOptions)
	if err != nil {
		log.Panic(err)
	}
	if _, err := os.Stat("private-repo-file"); os.IsNotExist(err) {
		log.Panic("repo did not clone!")
	}
	cloneOptions = &git.CloneOptions{
		CheckoutBranch: "main",
	}
	_, err = git.Clone("https://github.com/aws/eks-distro.git", "public-repo", cloneOptions)
	if err != nil {
		log.Panic(err)
	}
	if _, err := os.Stat("private-repo-file"); os.IsNotExist(err) {
		log.Panic("repo did not clone!")
	}

	fmt.Println("Successfully cloned!")
}
