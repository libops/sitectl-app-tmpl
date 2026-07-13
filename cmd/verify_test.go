package cmd

import (
	"testing"

	sitevalidate "github.com/libops/sitectl/pkg/validate"
	"github.com/spf13/cobra"
)

func TestAppVerifyRunnerDoesNotClaimUnimplementedBehavior(t *testing.T) {
	t.Parallel()

	results, err := (appVerifyRunner{}).Run(&cobra.Command{Use: "verify"}, nil)
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if len(results) != 1 {
		t.Fatalf("Run() returned %d results, want 1", len(results))
	}
	if results[0].Name != "verify:application" || results[0].Status != sitevalidate.StatusWarning {
		t.Fatalf("Run() result = %#v, want an explicit unimplemented warning", results[0])
	}
	if results[0].FixHint == "" {
		t.Fatalf("Run() result = %#v, want downstream implementation guidance", results[0])
	}
}
