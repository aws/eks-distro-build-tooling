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
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecrpublic"
	"github.com/pkg/errors"
)

// Function to create release clients for dev release
func (r *ReleaseConfig) CreateDevReleaseClients() (*ecrpublic.ECRPublic, error) {
	// IAD session for eks-d-build-prod-pdx
	session, err := session.NewSession(&aws.Config{
		Region: aws.String("us-east-1"),
	})
	if err != nil {
		return nil, errors.Cause(err)
	}

	// Create release ECR Public client
	ecrPublicClient := ecrpublic.New(session)

	return ecrPublicClient, nil
}

// Function to create clients for production release
func (r *ReleaseConfig) CreateProdReleaseClients() (*ecrpublic.ECRPublic, error) {
	// Session for eks-d-artifact-prod-iad
	session, err := session.NewSessionWithOptions(session.Options{
		Config: aws.Config{
			Region: aws.String("us-east-1"),
		},
		Profile: "release-account",
	})
	if err != nil {
		return nil, errors.Cause(err)
	}

	// Create release ECR Public client
	ecrPublicClient := ecrpublic.New(session)

	return ecrPublicClient, nil
}
