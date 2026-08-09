package cmd

import (
	"slices"
	"testing"

	sitectlplugin "github.com/libops/sitectl/pkg/plugin"
)

func TestAppExecCommandUsesAppService(t *testing.T) {
	t.Parallel()

	got := sitectlplugin.DockerComposeExecArgv(AppService, "python", "manage.py", "check")
	want := []string{"docker", "compose", "exec", "-T", "app", "python", "manage.py", "check"}
	if !slices.Equal(got, want) {
		t.Fatalf("DockerComposeExecArgv() = %#v, want %#v", got, want)
	}
}
