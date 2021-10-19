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

package main

import (
	"crypto/x509"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/user"
	"time"
)

func main() {
	pool, err := x509.SystemCertPool()
	if err != nil {
		fmt.Printf("Error %s loading system certs.\n", err)
		panic(err)
	}
	if pool == nil {
		fmt.Println("No cert pools.")
		os.Exit(1)
	}
	fmt.Println("Certs Loaded!")

	resp, err := http.Get("https://google.com")
	if err != nil {
		fmt.Printf("Error %s loading google.\n", err)
		panic(err)
	}
	defer resp.Body.Close()

	_, err = ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error %s loading google.\n", err)
		panic(err)
	}
	// manually set time zone
	if tz := os.Getenv("TZ"); tz != "" {
		var err error
		time.Local, err = time.LoadLocation(tz)
		if err != nil {
			log.Printf("error loading location '%s': %v\n", tz, err)
			panic(err)
		}
	}

	user, err := user.Current()
	if err != nil {
		panic(err)
	}

	// Current User
	if user.Name != "nobody" {
		panic("user name unexpected!")
	}
	if user.Uid != "65534" {
		panic("user name unexpected!")
	}
	if user.HomeDir != "/nonexistent" {
		panic("user home unexpected!")
	}

	f, err := ioutil.TempFile("", "sample")
	if err != nil {
		panic(err)
	}
	fmt.Println("Temp file name:", f.Name())
}
