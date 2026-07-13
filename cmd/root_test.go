package cmd

import (
	"strings"
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
	if len(spec.DockerComposeUp) != 1 || !strings.Contains(spec.DockerComposeUp[0], "--wait --wait-timeout 600") {
		t.Fatalf("create must wait for service health before reporting ready: %+v", spec.DockerComposeUp)
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
	assertRolloutContract(t, spec.DockerComposeRollout)
}

func TestRegisterCommands(t *testing.T) {
	t.Parallel()

	sdk := plugin.NewSDK(plugin.Metadata{
		Name: PluginName,
	})

	RegisterCommands(sdk)

	definitions := sdk.CreateDefinitions()
	if len(definitions) != 1 || definitions[0].Plugin != PluginName {
		t.Fatalf("standard app registration produced create definitions %+v", definitions)
	}

	components := map[string]bool{}
	for _, definition := range sdk.LocalComponentDefinitions() {
		components[definition.Name] = true
	}
	if !components["ingress"] {
		t.Fatalf("standard app registration did not register ingress: %+v", components)
	}
	if components["dev-mode"] {
		t.Fatalf("the scaffold must not register a broad development bind mount: %+v", components)
	}

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

func TestComposeProjectDiscoveryUsesApplicationIdentity(t *testing.T) {
	t.Parallel()

	discovery := composeProjectDiscovery()
	if len(discovery.RequiredServices) != 1 || discovery.RequiredServices[0] != AppService {
		t.Fatalf("RequiredServices = %+v, want only %q", discovery.RequiredServices, AppService)
	}
	if discovery.Reason != AppService+" service" {
		t.Fatalf("Reason = %q, want application service identity", discovery.Reason)
	}
}

func assertRolloutContract(t *testing.T, commands []string) {
	t.Helper()

	if len(commands) != 7 {
		t.Fatalf("rollout commands = %+v, want seven explicit lifecycle steps", commands)
	}
	if !strings.HasPrefix(commands[0], "docker compose pull ") || !strings.HasPrefix(commands[1], "docker compose build ") {
		t.Fatalf("pull and build must form the online preparation prefix: %+v", commands)
	}
	if commands[2] != "docker compose run --rm init" {
		t.Fatalf("idempotent init must run inside the outage window: %+v", commands)
	}
	appStart := commands[3]
	if appStart != "docker compose up --remove-orphans --pull missing --quiet-pull -d "+AppService || strings.Contains(appStart, "--wait") {
		t.Fatalf("initial start must target only the application service: %q", appStart)
	}
	if !strings.Contains(commands[4], "until test -f /installed") || !strings.Contains(commands[4], "-ge 150") {
		t.Fatalf("migration readiness must be bounded: %q", commands[4])
	}
	if !strings.Contains(commands[5], "ACTION REQUIRED") || !strings.Contains(commands[5], "migration") || !strings.Contains(commands[5], "exit 1") {
		t.Fatalf("the scaffold migration placeholder must fail closed: %q", commands[5])
	}
	fullStart := commands[6]
	if !strings.Contains(fullStart, "--wait --wait-timeout 600") || !strings.HasSuffix(fullStart, " -d") || strings.Contains(fullStart, "||") {
		t.Fatalf("final full-stack health wait must be bounded and fail hard: %q", fullStart)
	}
	for _, command := range commands {
		if command == "./scripts/rollout.sh" {
			t.Fatalf("rollout must be plugin-owned metadata: %+v", commands)
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
