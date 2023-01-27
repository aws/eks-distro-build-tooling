package cmd

import "github.com/spf13/cobra"

var (
	upstreampickerCmd = &cobra.Command{
		Use:   "upsteampicker",
		Short: "Upstream automation",
		Long:  "Tool for copying upstream issues into the projects repo. Currently used for duplicating Golang CVE issues into eks-distro-build-tooling",
	}
)

func init() {
	rootCmd.AddCommand(upstreampickerCmd)
}
