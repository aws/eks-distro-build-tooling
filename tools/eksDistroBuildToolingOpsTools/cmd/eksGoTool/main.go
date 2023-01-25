package main

import (
	"os"
	"os/signal"
	"syscall"

	"github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/cmd/eksGoTool/cmd"
)

func main() {
	sigChannel := make(chan os.Signal, 1)
	signal.Notify(sigChannel, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChannel
		os.Exit(-1)
	}()
	if cmd.Execute() == nil {
		os.Exit(0)
	}
	os.Exit(-1)
}
