import XCTest
@testable import BrowserManager

final class BrowserManagerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BrowserManager().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
