import XCTest
import CZTestUtils
@testable import SwiftPromise

final class SwiftPromiseTests: XCTestCase {
  static let result = "PromiseResult"
  static let error: Error? = NSError(domain: "Error", code: 999, userInfo: nil)
  static let asyncDelay: TimeInterval = 0.1
  
  func testResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(20, testCase: self)
    // Init promise.
    let promise = Promise<String> { (resolve, reject) in
      self.delayAsync {
        resolve(Self.result)
      }
    }
    // Test then().
    promise.then { (result) in
      XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
      expectation.fulfill()
      return nil
    }
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  func testReject() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(20, testCase: self)
    // Init promise.
    let promise = Promise<String> { (resolve, reject) in
      self.delayAsync {
        reject(Self.error)
      }
    }
    
    // Test catch().
    promise.then { result in
      XCTAssert(false, "then() shouldn't be called.")
      return nil
    }
    .catch{ error in
      print("error = \(error);")
      XCTAssertTrue(error as AnyObject === Self.error as AnyObject , "Actual result = \(error); Expected result = \(Self.error)")
      expectation.fulfill()
    }
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  func testAwaitWithResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(20, testCase: self)
    // Init promise.
    let promise = Promise<String> { (resolve, reject) in
      self.delayAsync {
        resolve(Self.result)
      }
    }
    // Test await().
    let result = promise.await()
    XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
    expectation.fulfill()
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  func testAwaitWithReject() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(20, testCase: self)
    // Init promise.
    let promise = Promise<String> { (resolve, reject) in
      self.delayAsync {
        reject(Self.error)
      }
    }
    // Test await().
    let result = promise.await()
    XCTAssertTrue(result == nil, "Actual result = \(result); Expected result = nil")
    expectation.fulfill()
    // Wait for asynchronous result.
    waitExpectation()
  }
}

private extension SwiftPromiseTests {
  func delayAsync(_ closure: @escaping () -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + Self.asyncDelay, execute: closure)
  }
}
