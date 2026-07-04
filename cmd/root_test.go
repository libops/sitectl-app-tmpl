package cmd

import (
	"testing"

	"github.com/libops/sitectl/pkg/plugin"
)

func TestCreateDefinition(t *testing.T) {
	t.Parallel()

	spec := createDefinition()
	if spec.Name != "default" {
		t.Fatalf("Name = %q, want default", spec.Name)
	}
	if spec.DockerComposeRepo != TemplateRepo {
		t.Fatalf("DockerComposeRepo = %q, want %q", spec.DockerComposeRepo, TemplateRepo)
	}
	if len(spec.DockerComposeUp) == 0 {
		t.Fatal("expected DockerComposeUp commands")
	}
	if len(spec.DockerComposeBuild) != 2 || spec.DockerComposeBuild[0] != "docker compose pull --ignore-buildable" {
		t.Fatalf("expected Docker Compose build commands, got %+v", spec.DockerComposeBuild)
	}
	if len(spec.DockerComposeInit) != 2 || spec.DockerComposeInit[1] != "docker compose run --rm init" {
		t.Fatalf("expected Docker Compose init commands, got %+v", spec.DockerComposeInit)
	}
	if len(spec.Images) != 1 || spec.Images[0].Service != AppService || spec.Images[0].Image != AppImage {
		t.Fatalf("expected app image metadata, got %+v", spec.Images)
	}
	if len(spec.InitArtifacts) == 0 || spec.InitArtifacts[0].Path != ".env" {
		t.Fatalf("expected init artifact metadata, got %+v", spec.InitArtifacts)
	}
	if len(spec.InitVolumes) != 1 || spec.InitVolumes[0].Name != DatabaseVolume {
		t.Fatalf("expected init volume metadata, got %+v", spec.InitVolumes)
	}
}

func TestRegisterCommands(t *testing.T) {
	t.Parallel()

	sdk := plugin.NewSDK(plugin.Metadata{
		Name: PluginName,
	})

	RegisterCommands(sdk)

	for _, name := range []string{"build", "init", "up", "down", "status", "logs", "rollout"} {
		if hasRootCommand(sdk, name) {
			t.Fatalf("did not expect core lifecycle command %q to be registered by the plugin", name)
		}
	}

	for _, name := range []string{"exec"} {
		if !hasRootCommand(sdk, name) {
			t.Fatalf("expected plugin command %q to be registered", name)
		}
	}
}

func hasRootCommand(sdk *plugin.SDK, name string) bool {
	for _, cmd := range sdk.RootCmd.Commands() {
		if cmd.Name() == name {
			return true
		}
	}
	return false
}
