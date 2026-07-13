package cmd

import (
	"github.com/libops/sitectl/pkg/plugin"
	coretraefik "github.com/libops/sitectl/pkg/services/traefik"
)

const (
	PluginName             = "app-tmpl"
	DisplayName            = "App Template"
	TemplateRepo           = "https://github.com/libops/app-tmpl"
	TemplateBranch         = "main"
	DefaultPath            = "./app"
	AppService             = "app"
	AppImage               = "libops/app:local"
	DatabaseService        = "mariadb"
	DatabaseUser           = "app"
	DatabaseName           = "app"
	DatabaseVolume         = "mariadb-data"
	DatabaseRootSecret     = "DB_ROOT_PASSWORD"
	DatabasePasswordSecret = "APP_DB_PASSWORD"
	SearchService          = "solr"
	FrontendService        = "traefik"
	DefaultCodebaseRootfs  = "app"
)

func composeProjectDiscovery() plugin.ComposeProjectDiscovery {
	return plugin.ComposeProjectDiscovery{
		RequiredServices: []string{AppService},
		Reason:           AppService + " service",
	}
}

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
		DockerComposeDown: []string{"docker compose down"},
		DockerComposeRollout: []string{
			"docker compose pull --ignore-buildable --quiet || docker compose pull --ignore-buildable",
			"docker compose build --pull",
			"docker compose run --rm init",
			"docker compose up --remove-orphans --pull missing --quiet-pull -d " + AppService,
			"docker compose exec -T " + AppService + " sh -c 'attempt=0; until test -f /installed; do attempt=$((attempt + 1)); if [ \"$attempt\" -ge 150 ]; then echo \"Application did not become ready for database migration within 5 minutes\" >&2; exit 1; fi; sleep 2; done'",
			"printf '%s\\n' 'ACTION REQUIRED: replace this fail-closed template command with the application-supported database migration or an explicit manual migration gate before release.' >&2; exit 1",
			"docker compose up --remove-orphans --wait --wait-timeout 600 --pull missing --quiet-pull -d",
		},
	}
}

// RegisterCommands registers application commands with the plugin SDK.
func RegisterCommands(s *plugin.SDK) {
	s.MustRegisterStandardComposeAppPlugin(plugin.StandardComposeAppPluginOptions{
		PluginName:   PluginName,
		DisplayName:  DisplayName,
		AppService:   AppService,
		Router:       AppService,
		DefaultPath:  DefaultPath,
		ReadyMessage: DisplayName + " is ready for use through sitectl.",
		Discovery:    composeProjectDiscovery(),
		CreateSpec:   createDefinition(),
		CreateOptions: plugin.ComposeTemplateCreateOptions{
			DefaultDatabaseService:        DatabaseService,
			DefaultDatabaseUser:           DatabaseUser,
			DefaultDatabasePasswordSecret: DatabasePasswordSecret,
			DefaultDatabaseName:           DatabaseName,
		},
		IngressOptions: coretraefik.IngressOptions{
			AppService:      AppService,
			TraefikService:  FrontendService,
			HTTPEntrypoint:  "web",
			HTTPSEntrypoint: "websecure",
		},
		DisableDevMode: true,
		Healthcheck: plugin.StandardComposeWebHealthcheck(plugin.StandardComposeWebHealthcheckOptions{
			AppService:              AppService,
			TraefikRouter:           AppService,
			DatabaseService:         DatabaseService,
			CheckDatabaseDependency: true,
			SolrService:             SearchService,
			SolrCore:                "default",
		}),
	})
	s.RegisterVerifyRunner(appVerifyRunner{})
	registerAppCommands(s)
	registerDiagnostics(s)
}
