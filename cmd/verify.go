package cmd

import (
	"github.com/libops/sitectl/pkg/config"
	"github.com/libops/sitectl/pkg/plugin"
	sitevalidate "github.com/libops/sitectl/pkg/validate"
	"github.com/spf13/cobra"
)

type appVerifyRunner struct{}

func (appVerifyRunner) BindFlags(cmd *cobra.Command) {}

func (appVerifyRunner) Run(cmd *cobra.Command, ctx *config.Context) ([]sitevalidate.Result, error) {
	return []sitevalidate.Result{{
		Name:    "verify:application",
		Status:  sitevalidate.StatusWarning,
		Detail:  "No application-specific behavioral verification is configured.",
		FixHint: "Replace appVerifyRunner with checks for a real application workflow before releasing the plugin.",
	}}, nil
}

var _ plugin.VerifyRunner = appVerifyRunner{}
