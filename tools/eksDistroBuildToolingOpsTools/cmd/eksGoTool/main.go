package main

import (
	cmd2 "github.com/aws/eks-distro-build-tooling/tools/eksDistroBuildToolingOpsTools/cmd/eksGoTool/cmd"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	sigChannel := make(chan os.Signal, 1)
	signal.Notify(sigChannel, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChannel
		os.Exit(-1)
	}()
	if cmd2.Execute() == nil {
		os.Exit(0)
	}
	os.Exit(-1)
}