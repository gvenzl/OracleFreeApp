import Testing
@testable import OracleFreeKit

struct OracleConnectionInfoTests {
    @Test func connectionInfoBuildsOracleConnectionString() {
        #expect(OracleConnectionInfo.default.connectionString == "system/OracleFree123@localhost:1521/FREEPDB1")
    }
}
