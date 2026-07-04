package cmd

import (
	"fmt"
	"strings"

	"github.com/libops/sitectl/pkg/config"
	sitectlplugin "github.com/libops/sitectl/pkg/plugin"
	"github.com/libops/sitectl/pkg/plugin/debugui"
	sitevalidate "github.com/libops/sitectl/pkg/validate"
	"github.com/spf13/cobra"
)

type appDebugRunner struct {
	verbose bool
}

func registerDiagnostics(s *sitectlplugin.SDK) {
	s.RegisterDebugRunner(&appDebugRunner{})
	s.RegisterValidateRunner(&appValidateRunner{})
}

func (r *appDebugRunner) BindFlags(cmd *cobra.Command) {
	cmd.Flags().BoolVar(&r.verbose, "verbose", false, "Show detailed debug output")
}

func (r *appDebugRunner) Render(cmd *cobra.Command, ctx *config.Context) (string, error) {
	rows := []debugui.Row{
		{Label: "Plugin", Value: PluginName},
		{Label: "App service", Value: AppService},
		{Label: "Database", Value: DatabaseName},
		{Label: "Database service", Value: DatabaseService},
		{Label: "Search service", Value: SearchService},
		{Label: "Frontend", Value: FrontendService},
		{Label: "Codebase rootfs", Value: DefaultCodebaseRootfs},
	}
	if ctx != nil {
		rows = append(rows,
			debugui.Row{Label: "Context", Value: ctx.Name},
			debugui.Row{Label: "Project", Value: ctx.ProjectDir},
			debugui.Row{Label: "Environment", Value: ctx.Environment},
		)
	}
	if r.verbose {
		rows = append(rows, debugui.Row{Label: "Shared services", Value: sharedServiceList()})
	}
	return debugui.FormatRows(rows), nil
}

type appValidateRunner struct {
	codebaseRootfs string
}

func (r *appValidateRunner) BindFlags(cmd *cobra.Command) {
	cmd.Flags().StringVar(&r.codebaseRootfs, "codebase-rootfs", DefaultCodebaseRootfs, "Path to the app codebase inside the Compose project")
}

func (r *appValidateRunner) Run(cmd *cobra.Command, ctx *config.Context) ([]sitevalidate.Result, error) {
	results := []sitevalidate.Result{
		{
			Name:   "app service",
			Status: sitevalidate.StatusOK,
			Detail: AppService,
		},
		{
			Name:   "shared services",
			Status: sitevalidate.StatusOK,
			Detail: sharedServiceList(),
		},
	}

	if ctx == nil {
		results = append(results, sitevalidate.Result{
			Name:   "context",
			Status: sitevalidate.StatusFailed,
			Detail: "No active sitectl context was loaded.",
		})
		return results, nil
	}

	results = append(results, validateNonEmpty("project directory", ctx.ProjectDir, "Set project-dir on the sitectl context."))
	results = append(results, validateNonEmpty("compose project", ctx.ProjectName, "Set project-name on the sitectl context."))

	codebaseRootfs := strings.TrimSpace(r.codebaseRootfs)
	if codebaseRootfs == "" {
		results = append(results, sitevalidate.Result{
			Name:    "codebase rootfs",
			Status:  sitevalidate.StatusWarning,
			Detail:  "No codebase rootfs path is configured.",
			FixHint: "Set DefaultCodebaseRootfs in cmd/root.go or pass --codebase-rootfs.",
		})
	} else {
		results = append(results, sitevalidate.Result{
			Name:   "codebase rootfs",
			Status: sitevalidate.StatusOK,
			Detail: codebaseRootfs,
		})
	}

	return results, nil
}

func sharedServiceList() string {
	services := []string{DatabaseService, SearchService, FrontendService}
	out := make([]string, 0, len(services))
	for _, service := range services {
		service = strings.TrimSpace(service)
		if service != "" {
			out = append(out, service)
		}
	}
	return strings.Join(out, ", ")
}

func validateNonEmpty(name, value, fixHint string) sitevalidate.Result {
	value = strings.TrimSpace(value)
	if value == "" {
		return sitevalidate.Result{
			Name:    name,
			Status:  sitevalidate.StatusFailed,
			Detail:  fmt.Sprintf("%s is not configured.", name),
			FixHint: fixHint,
		}
	}
	return sitevalidate.Result{
		Name:   name,
		Status: sitevalidate.StatusOK,
		Detail: value,
	}
}
