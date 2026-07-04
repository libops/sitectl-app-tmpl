package cmd

import (
	"strings"

	"github.com/libops/sitectl/pkg/config"
	"github.com/libops/sitectl/pkg/healthcheck"
	"github.com/libops/sitectl/pkg/plugin"
	sitevalidate "github.com/libops/sitectl/pkg/validate"
	"github.com/spf13/cobra"
)

type appHealthcheckRunner struct{}

func (appHealthcheckRunner) BindFlags(cmd *cobra.Command) {}

func (appHealthcheckRunner) Run(cmd *cobra.Command, ctx *config.Context) ([]sitevalidate.Result, error) {
	targetURL := healthcheck.PublicURLFromEnv(ctx, "http", "localhost")
	if traefikURL, ok, err := healthcheck.PublicURLFromTraefik(ctx, healthcheck.TraefikRouteOptions{
		AppService:    AppService,
		Router:        AppService,
		DefaultScheme: "http",
		DefaultDomain: "localhost",
	}); err == nil && ok {
		targetURL = traefikURL
	}

	results := []sitevalidate.Result{
		healthcheck.CheckHTTP(cmd.Context(), "http:"+AppService, targetURL),
	}

	checker, err := healthcheck.NewDockerChecker(ctx)
	if err != nil {
		return nil, err
	}
	defer func() { _ = checker.Close() }()

	results = append(results, checker.CheckMariaDB(cmd.Context(), DatabaseService))
	if strings.TrimSpace(SearchService) != "" {
		results = append(results, checker.CheckSolrCore(cmd.Context(), SearchService, "default"))
	}
	return results, nil
}

var _ plugin.HealthcheckRunner = appHealthcheckRunner{}
