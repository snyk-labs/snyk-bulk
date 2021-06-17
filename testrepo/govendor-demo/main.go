package main

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var (
	rootCmd = &cobra.Command{
		Use:   "godep-demo",
		Short: "Showing how godep works",
		Long:  "Showing how godep works",
		Run:   CmdRoot,
	}
)

func CmdRoot(cd *cobra.Command, args []string) {
	log.Info("Important work")
}

func main() {
	log.Info("Starting up")

	rootCmd.Flags().StringP("key", "k", "", "Github API key")

	rootCmd.Execute()

	log.Info("Done")
}
