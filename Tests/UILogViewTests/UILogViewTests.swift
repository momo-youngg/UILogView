import XCTest
@testable import UILogView

final class UILogViewTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(UILogView().text, "Hello, World!")
    }
}
