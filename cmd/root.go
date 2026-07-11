package cmd

import "github.com/libops/sitectl/pkg/plugin"

const (
	PluginName             = "app-tmpl"
	DisplayName            = "App Template"
	TemplateRepo           = "https://github.com/libops/app-tmpl"
	TemplateBranch         = "main"
	DefaultPath            = "./app"
	AppService             = "app"
	AppImage               = "libops/app:local"
	DatabaseService        = "mariadb"
	DatabaseName           = "app"
	DatabaseVolume         = "mariadb-data"
	DatabaseRootSecret     = "DB_ROOT_PASSWORD"
	DatabasePasswordSecret = "APP_DB_PASSWORD"
	SearchService          = "solr"
	FrontendService        = "traefik"
	DefaultCodebaseRootfs  = "app"
)

func createDefinition() plugin.CreateSpec {
	return plugin.CreateSpec{
		Name:                "default",
		Description:         "Create an application stack",
		Default:             true,
		MinCPUCores:         2,
		MinMemory:           "4 GiB",
		MinDiskSpace:        "20 GiB",
		DockerComposeRepo:   TemplateRepo,
		DockerComposeBranch: TemplateBranch,
		DockerComposeBuild: []string{
			"docker compose pull --ignore-buildable",
			"docker compose build --pull",
		},
		Images: []plugin.ComposeImageSpec{
			{Service: AppService, Image: AppImage, BuildPolicy: plugin.BuildPolicyIfNotPresent},
		},
		DockerComposeInit: []string{
			"if [ ! -f .env ]; then cp sample.env .env; fi",
			"docker compose run --rm init",
		},
		InitArtifacts: []plugin.InitArtifact{
			{Path: ".env"},
			{Path: "secrets/" + DatabaseRootSecret},
			{Path: "secrets/" + DatabasePasswordSecret},
		},
		InitVolumes: []plugin.InitVolume{
			{Name: DatabaseVolume},
		},
		DockerComposeUp: []string{
			"docker compose up --remove-orphans --wait --wait-timeout 600 -d",
		},
		DockerComposeDown:    []string{"docker compose down"},
		DockerComposeRollout: []string{"./scripts/rollout.sh"},
	}
}

// RegisterCommands registers application commands with the plugin SDK.
func RegisterCommands(s *plugin.SDK) {
	s.SetComposeProjectDiscovery(plugin.ComposeProjectDiscovery{
		RequiredServices: []string{AppService, DatabaseService, SearchService, FrontendService},
		Reason:           "app stack with app, mariadb, solr, and traefik services",
	})
	s.RegisterComposeTemplateCreateRunner(createDefinition(), plugin.ComposeTemplateCreateOptions{
		DefaultPath:   DefaultPath,
		DefaultPlugin: PluginName,
		ReadyMessage:  DisplayName + " is ready for use through sitectl.",
	})
	s.RegisterHealthcheckRunner(appHealthcheckRunner{})
	registerAppCommands(s)
	registerDiagnostics(s)
}
