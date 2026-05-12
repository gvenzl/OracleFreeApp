import Testing
@testable import OracleFreeKit

struct OracleFreeAppMetadataTests {
    @Test func metadataDefinesApplicationDisplayNameAuthorAndVersion() {
        #expect(OracleFreeAppMetadata.displayName == "Oracle Free App")
        #expect(OracleFreeAppMetadata.author == "Gerald Venzl")
        #expect(!OracleFreeAppMetadata.version.isEmpty)
    }

    @Test func metadataVersionMatchesRootVersionFile() throws {
        let version = try String(contentsOfFile: "VERSION", encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(OracleFreeAppMetadata.version == version)
    }
}
