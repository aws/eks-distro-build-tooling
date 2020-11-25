/*
Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License"). You may
not use this file except in compliance with the License. A copy of the
License is located at

    http://aws.amazon.com/apache2.0/

or in the "license" file accompanying this file. This file is distributed
on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
express or implied. See the License for the specific language governing
permissions and limitations under the License.
*/
package pkg

import (
	"reflect"
	"strings"
	"testing"
)

func TestReadKubeVersion(t *testing.T) {
	cases := []struct {
		name       string
		content    string
		want       *kubeGitVersionFile
		wantErrMsg string
	}{
		{
			name: "valid file",
			content: `KUBE_GIT_COMMIT='94f372e501c973a7fa9eb40ec9ebd2fe7ca69848'
KUBE_GIT_VERSION='v1.18.9-eks-1-18-1'
KUBE_GIT_MAJOR='1'
KUBE_GIT_MINOR='18'
SOURCE_DATE_EPOCH='1600264008'
KUBE_GIT_TREE_STATE='archive'`,
			want: &kubeGitVersionFile{
				KubeGitCommit:    "94f372e501c973a7fa9eb40ec9ebd2fe7ca69848",
				KubeGitVersion:   "v1.18.9-eks-1-18-1",
				KubeGitMajor:     1,
				KubeGitMinor:     18,
				SourceDateEpoch:  1600264008,
				KubeGitTreeState: "archive",
			},
			wantErrMsg: "",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			reader := strings.NewReader(tc.content)
			got, err := parseKubeGitVersionContent(reader)
			if err != nil && err.Error() != tc.wantErrMsg {
				t.Errorf("Incorrect error message: Got '%s', wanted '%s'", err.Error(), tc.wantErrMsg)
			}
			if !reflect.DeepEqual(got, tc.want) {
				t.Errorf("Incorrect response: Got %#v, wanted %#v", got, tc.want)
			}
		})
	}
}
