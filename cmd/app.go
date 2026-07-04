package cmd

import (
	sitectlplugin "github.com/libops/sitectl/pkg/plugin"
	"github.com/spf13/cobra"
)

func registerAppCommands(s *sitectlplugin.SDK) {
	s.AddCommand(appExecCommand(s))
}

func appExecCommand(s *sitectlplugin.SDK) *cobra.Command {
	return &cobra.Command{
		Use:                "exec COMMAND [args...]",
		Short:              "Run a command in the app service container",
		Args:               cobra.MinimumNArgs(1),
		DisableFlagParsing: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runAppExec(s, cmd, args...)
		},
	}
}

func runAppExec(s *sitectlplugin.SDK, cmd *cobra.Command, args ...string) error {
	return s.RunActiveComposeProjectCommand(cmd, sitectlplugin.DockerComposeExecCommand(AppService, args...))
}
