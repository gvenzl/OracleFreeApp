import Testing
@testable import OracleFreeKit

struct OracleContainerConfigurationTests {
    @Test func defaultConfigurationDefinesImagePortsVolumeAndEnvironment() {
        let configuration = OracleContainerConfiguration.default

        #expect(configuration.containerName == "oracle-free")
        #expect(configuration.image == "ghcr.io/gvenzl/oracle-free")
        #expect(configuration.hostPort == 1521)
        #expect(configuration.databasePort == 1521)
        #expect(configuration.volumeName == "oracle-free-data")
        #expect(configuration.healthCheck == ContainerHealthCheckConfiguration(
            command: "healthcheck.sh",
            interval: "10s",
            timeout: "5s",
            retries: 10
        ))
        #expect(configuration.environmentVariables == [
            ContainerEnvironmentVariable(name: "ORACLE_PASSWORD", value: "OracleFree123")
        ])
    }
}
