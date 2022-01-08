// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
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
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"
	"strings"

	distrov1alpha1 "github.com/aws/eks-distro-build-tooling/release/api/v1alpha1"
	"github.com/pkg/errors"
	"sigs.k8s.io/yaml"
)

func readTag(filename string) (string, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", errors.Cause(err)
	}
	return strings.TrimSpace(string(data)), nil
}

func (r *ReleaseConfig) readShaSums(filename string) (sha256, sha512 string, err error) {

	sha256Path := filename + ".sha256"
	sha256, err = readShaFile(sha256Path)
	if err != nil {
		return "", "", errors.Cause(err)
	}
	sha512Path := filename + ".sha512"
	sha512, err = readShaFile(sha512Path)
	if err != nil {
		return "", "", errors.Cause(err)
	}
	return sha256, sha512, nil
}

func readShaFile(filename string) (string, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", errors.Cause(err)
	}
	if parts := strings.Split(string(data), "  "); len(parts) == 2 {
		return parts[0], nil
	}
	return "", errors.Errorf("Error parsing shasum file %s", filename)
}

func GetEksDistroReleaseManifestUrl(releaseChannel, releaseNumber string) string {
	manifestUrl := fmt.Sprintf("https://distro.eks.amazonaws.com/kubernetes-%[1]s/kubernetes-%[1]s-eks-%s.yaml", releaseChannel, releaseNumber)
	return manifestUrl
}

func ParseEksDistroReleaseManifestUrl(releaseManifestUrl string) (string, string) {
	r := regexp.MustCompile(`^https://distro.eks.amazonaws.com/kubernetes-\d-\d+/kubernetes-(?P<ReleaseBranch>\d-\d+)-eks-(?P<ReleaseNumber>\d+).yaml$`)
	search := r.FindStringSubmatch(releaseManifestUrl)
	return search[1], search[2]
}

func getEksdRelease(eksdReleaseURL string) (*distrov1alpha1.Release, error) {
	content, err := readHttpFile(eksdReleaseURL)
	if err != nil {
		return nil, err
	}

	eksd := &distrov1alpha1.Release{}
	if err = yaml.UnmarshalStrict(content, eksd); err != nil {
		return nil, errors.Wrapf(err, "failed to unmarshal eksd manifest")
	}

	return eksd, nil
}

func readHttpFile(uri string) ([]byte, error) {
	resp, err := http.Get(uri)
	if err != nil {
		return nil, errors.Wrapf(err, "failed reading file from url [%s]", uri)
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, errors.Wrapf(err, "failed reading file from url [%s]", uri)
	}

	return data, nil
}

func sliceContains(s []string, str string) bool {
	for _, elem := range s {
		if elem == str {
			return true
		}
	}
	return false
}
