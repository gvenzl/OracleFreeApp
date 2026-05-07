import Testing
@testable import OracleFreeKit

struct OracleContainerSettingsTests {
    @Test func defaultSettingsMatchOracleFreeDefaults() {
        let settings = OracleContainerSettings.default

        #expect(settings.image == "ghcr.io/gvenzl/oracle-free")
        #expect(settings.containerName == "oracle-free")
        #expect(settings.hostPort == 1521)
        #expect(settings.volumeName == "oracle-free-data")
        #expect(settings.password == "OracleFree123")
        #expect(settings.extraEnvironmentVariables == [])
    }

    @Test func settingsBuildContainerConfigurationWithPasswordAndExtraEnvironment() {
        let settings = OracleContainerSettings(
            image: "ghcr.io/gvenzl/oracle-free:slim",
            containerName: "oracle-dev",
            hostPort: 11521,
            volumeName: "oracle-dev-data",
            password: "LocalPassword123",
            extraEnvironmentVariables: [
                ContainerEnvironmentVariable(name: "APP_USER", value: "demo"),
                ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: "IgnoredPassword")
            ]
        )

        let configuration = settings.containerConfiguration()

        #expect(configuration.containerName == "oracle-dev")
        #expect(configuration.image == "ghcr.io/gvenzl/oracle-free:slim")
        #expect(configuration.databasePort == 1521)
        #expect(configuration.hostPort == 11521)
        #expect(configuration.volumeName == "oracle-dev-data")
        #expect(configuration.environmentVariables == [
            ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: "LocalPassword123"),
            ContainerEnvironmentVariable(name: "APP_USER", value: "demo")
        ])
    }

    @Test func settingsUppercaseExtraEnvironmentVariableKeys() {
        let settings = OracleContainerSettings(
            image: "ghcr.io/gvenzl/oracle-free:slim",
            containerName: "oracle-dev",
            hostPort: 11521,
            volumeName: "oracle-dev-data",
            password: "LocalPassword123",
            extraEnvironmentVariables: [
                ContainerEnvironmentVariable(name: "app_user", value: "demo"),
                ContainerEnvironmentVariable(name: "oracle_password", value: "IgnoredPassword")
            ]
        )

        let configuration = settings.containerConfiguration()

        #expect(settings.extraEnvironmentVariables == [
            ContainerEnvironmentVariable(name: "APP_USER", value: "demo"),
            ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: "IgnoredPassword")
        ])
        #expect(configuration.environmentVariables == [
            ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: "LocalPassword123"),
            ContainerEnvironmentVariable(name: "APP_USER", value: "demo")
        ])
    }

    @Test func settingsIgnoreBlankEnvironmentVariableKeys() {
        let settings = OracleContainerSettings(
            image: "ghcr.io/gvenzl/oracle-free:slim",
            containerName: "oracle-dev",
            hostPort: 11521,
            volumeName: "oracle-dev-data",
            password: "LocalPassword123",
            extraEnvironmentVariables: [
                ContainerEnvironmentVariable(name: "", value: "ignored"),
                ContainerEnvironmentVariable(name: "  ", value: "ignored"),
                ContainerEnvironmentVariable(name: "APP_USER", value: "demo")
            ]
        )

        let configuration = settings.containerConfiguration()

        #expect(configuration.environmentVariables == [
            ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: "LocalPassword123"),
            ContainerEnvironmentVariable(name: "APP_USER", value: "demo")
        ])
    }

    @Test func settingsParsesExtraEnvironmentVariableText() {
        let variables = OracleContainerSettings.extraEnvironmentVariables(from: """
        APP_USER=demo

        ENABLE_ARCHIVELOG=true
        INVALID_LINE
        """)

        #expect(variables == [
            ContainerEnvironmentVariable(name: "APP_USER", value: "demo"),
            ContainerEnvironmentVariable(name: "ENABLE_ARCHIVELOG", value: "true")
        ])
    }

    @Test func settingsParsesEnvironmentVariableKeysAsUppercase() {
        let variables = OracleContainerSettings.extraEnvironmentVariables(from: """
        app_user=demo
        nls_lang=AMERICAN_AMERICA.AL32UTF8
        """)

        #expect(variables == [
            ContainerEnvironmentVariable(name: "APP_USER", value: "demo"),
            ContainerEnvironmentVariable(name: "NLS_LANG", value: "AMERICAN_AMERICA.AL32UTF8")
        ])
    }
}
