package cmd

import (
	"testing"

	"github.com/libops/sitectl/pkg/config"
	sitevalidate "github.com/libops/sitectl/pkg/validate"
	"github.com/spf13/cobra"
)

func TestAppValidateRunnerReportsContextFailures(t *testing.T) {
	t.Parallel()

	runner := &appValidateRunner{}
	cmd := &cobra.Command{Use: "validate"}
	runner.BindFlags(cmd)

	results, err := runner.Run(cmd, &config.Context{})
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if !hasValidationResult(results, "project directory", sitevalidate.StatusFailed) {
		t.Fatalf("expected failed project directory result, got %#v", results)
	}
}

func TestAppValidateRunnerReportsConfiguredContext(t *testing.T) {
	t.Parallel()

	runner := &appValidateRunner{}
	cmd := &cobra.Command{Use: "validate"}
	runner.BindFlags(cmd)

	results, err := runner.Run(cmd, &config.Context{
		ProjectDir:  "/srv/app",
		ProjectName: "app",
	})
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if !hasValidationResult(results, "project directory", sitevalidate.StatusOK) {
		t.Fatalf("expected ok project directory result, got %#v", results)
	}
	if !hasValidationResult(results, "codebase rootfs", sitevalidate.StatusOK) {
		t.Fatalf("expected ok codebase rootfs result, got %#v", results)
	}
}

func hasValidationResult(results []sitevalidate.Result, name, status string) bool {
	for _, result := range results {
		if result.Name == name && result.Status == status {
			return true
		}
	}
	return false
}
