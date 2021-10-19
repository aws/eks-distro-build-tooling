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
	"io/ioutil"
	"strings"

	"github.com/pkg/errors"
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
