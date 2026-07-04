package cmd

import (
	"testing"

	sitectlplugin "github.com/libops/sitectl/pkg/plugin"
)

func TestAppExecCommandUsesAppService(t *testing.T) {
	t.Parallel()

	got := sitectlplugin.DockerComposeExecCommand(AppService, "python", "manage.py", "check")
	want := "'docker' 'compose' 'exec' '-T' 'app' 'python' 'manage.py' 'check'"
	if got != want {
		t.Fatalf("DockerComposeExecCommand() = %q, want %q", got, want)
	}
}
