import Testing
@testable import OracleFreeKit

struct OracleFreeAppMetadataTests {
    @Test func metadataDefinesApplicationDisplayNameAuthorAndVersion() {
        #expect(OracleFreeAppMetadata.displayName == "Oracle Free App")
        #expect(OracleFreeAppMetadata.author == "Gerald Venzl")
        #expect(OracleFreeAppMetadata.version == "1.0.0")
    }
}
