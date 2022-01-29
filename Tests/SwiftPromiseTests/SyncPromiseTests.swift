import XCTest
import CZTestUtils
@testable import SwiftPromise

final class SyncPromiseTests: XCTestCase {
  static let result = "PromiseResult"
  static let chainingThenPromiseResult = "chainingThenPromiseResult"
  static let error: Error? = NSError(domain: "Error", code: 999, userInfo: nil)
  static let asyncDelay: TimeInterval = 0.1
  static let fulfillWaitInterval: TimeInterval = 30
  
  // MARK: - Test resolve() / reject()
  
  func testResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise()
    // Test then().
    promise.then { (result) in
      XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
      expectation.fulfill()
      return nil
    }
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  /**
   Test chaining multitple `then`.
   */
  func testChainingThenResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise(shouldAsync: false)

    // Test chaining then().
    promise
      .then { (result) in
        XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
        return Self.chainingThenPromiseResult
      }
    // * Note: next then() will call the same promise, as prev then() method returns `self`.
      .then { (result) in
        XCTAssertEqual(result as! String, Self.chainingThenPromiseResult)
        expectation.fulfill()
        return nil
      }

    // Wait for asynchronous result.
    waitExpectation()
  }
  
}

// MARK: - Convenience methods

private extension SyncPromiseTests {

  func createPromise(shouldAsync: Bool = true, shouldReject: Bool = false) -> SyncPromise<String> {
    let promise = SyncPromise<String> { (resolve, reject) in
      self.delayAsync(shouldAsync: shouldAsync) {
        if shouldReject {
          reject(Self.error)
        } else {
          resolve(Self.result)
        }
      }
    }
    return promise
  }
  
  func delayAsync(shouldAsync: Bool = true, _ closure: @escaping () -> Void) {
    if shouldAsync {
      DispatchQueue.global().asyncAfter(deadline: .now() + Self.asyncDelay, execute: closure)
    } else {
      closure()
    }
  }
}
