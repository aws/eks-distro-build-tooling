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

package pkg

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/pkg/errors"
)

func (r *ReleaseConfig) ReadK8sShaSums(gitTag, filename string) (sha256, sha512 string, err error) {
	dirname := fmt.Sprintf("kubernetes/%s/", gitTag)
	assetFile := filepath.Join(r.ArtifactDir, dirname, filename)
	return r.readShaSums(assetFile)
}

func (r *ReleaseConfig) readK8sTag(buildSource, releaseBranch string) (string, error) {
	return readTag(filepath.Join(buildSource, "projects/kubernetes/kubernetes", releaseBranch, "GIT_TAG"))
}

type kubeGitVersionFile struct {
	KubeGitCommit    string
	KubeGitVersion   string
	KubeGitMajor     int
	KubeGitMinor     int
	SourceDateEpoch  int
	KubeGitTreeState string
}

func newKubeGitVersionFile(buildSource, releaseBranch string) (*kubeGitVersionFile, error) {
	versionFile := filepath.Join(buildSource, "projects/kubernetes/kubernetes", releaseBranch, "KUBE_GIT_VERSION_FILE")
	f, err := os.Open(versionFile)
	if err != nil {
		return nil, err
	}
	return parseKubeGitVersionContent(f)
}

func parseKubeGitVersionContent(input io.Reader) (*kubeGitVersionFile, error) {
	resp := &kubeGitVersionFile{}
	scanner := bufio.NewScanner(input)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			return nil, errors.Errorf("no equal sign in line: %s", line)
		}
		value := strings.Trim(parts[1], `'`)
		switch parts[0] {
		case "KUBE_GIT_COMMIT":
			resp.KubeGitCommit = value
		case "KUBE_GIT_VERSION":
			resp.KubeGitVersion = value
		case "KUBE_GIT_MAJOR":
			val, err := strconv.Atoi(value)
			if err != nil {
				return nil, errors.Wrapf(err, "Could not parse '%s'", value)
			}
			resp.KubeGitMajor = val
		case "KUBE_GIT_MINOR":
			val, err := strconv.Atoi(value)
			if err != nil {
				return nil, errors.Wrapf(err, "Could not parse '%s'", value)
			}
			resp.KubeGitMinor = val
		case "SOURCE_DATE_EPOCH":
			val, err := strconv.Atoi(value)
			if err != nil {
				return nil, errors.Wrapf(err, "Could not parse '%s'", value)
			}
			resp.SourceDateEpoch = val
		case "KUBE_GIT_TREE_STATE":
			resp.KubeGitTreeState = value
		default:
		}

	}
	if err := scanner.Err(); err != nil {
		return nil, errors.Wrap(err, "Error reading KUBE_GIT_VERSION_FILE")
	}
	return resp, nil
}
