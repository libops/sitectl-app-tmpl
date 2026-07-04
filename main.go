package main

import (
	"fmt"

	"github.com/libops/sitectl-app-tmpl/cmd"
	"github.com/libops/sitectl/pkg/plugin"
)

var (
	version = "dev"
	commit  = "none"
	date    = "unknown"
)

func main() {
	sdk := plugin.NewSDK(plugin.Metadata{
		Name:         cmd.PluginName,
		Version:      fmt.Sprintf("%s (Built on %s from Git SHA %s)", version, date, commit),
		Description:  cmd.DisplayName + " helpers",
		Author:       "libops",
		TemplateRepo: cmd.TemplateRepo,
	})

	cmd.RegisterCommands(sdk)
	sdk.Execute()
}
