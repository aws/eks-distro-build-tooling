package main

import {
	"github.com/aws/eks-distro-build-tooling/slim-jim/cmd/slim-jim/cmd"
	"os"
}

func main() {
	if cmd.Execute() == nil {
		os.Exit(0)
	}
	os.Exit(-1)
}
