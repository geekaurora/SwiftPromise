import XCTest
import CZTestUtils
@testable import SwiftPromise

final class SwiftPromiseTests: XCTestCase {
  static let result = "PromiseResult"
  static let error: Error? = NSError(domain: "Error", code: 999, userInfo: nil)
  static let asyncDelay: TimeInterval = 0.1
  static let fulfillWaitInterval: TimeInterval = 20
  
  // MARK: - Test resolve()/reject()
  
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
  
  func testReject() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise(shouldReject: true)
    
    // Test catch().
    promise.then { result in
      XCTAssert(false, "then() shouldn't be called.")
      return nil
    }
    .catch { error in
      XCTAssertTrue(error as AnyObject === Self.error as AnyObject , "Actual result = \(error); Expected result = \(Self.error)")
      expectation.fulfill()
    }
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  func testChainingThenResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise()
    
    // Test chaining then().
    promise
      .then { (result) in
        XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
        return self.createPromise()
    }
    .then { (result) in
      XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
      expectation.fulfill()
      return nil
    }
    
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  // MARK: - Test all()
  
  func testAllPromisesResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promises = [createPromise(), createPromise()]
        
    // Test then().
    Promise.all(promises).then { (result) in
      XCTAssertTrue(
        result == Promise<Any>.allPromisesSuccessString,
        "Actual result = \(result); Expected result = \(Promise<Any>.allPromisesSuccessString)")
      expectation.fulfill()
      return nil
    }
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  func testAllPromisesReject() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promises = [createPromise(), createPromise(), createPromise(shouldReject: true)]
    
    // Test then().
    Promise.all(promises).then { _ in
      XCTAssertTrue(false, "then() shouldn't be called.")
      return nil
    }.catch { error in
      XCTAssertTrue(error as AnyObject === Self.error as AnyObject , "Actual result = \(error); Expected result = \(Self.error)")
      expectation.fulfill()
    }
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  // MARK: - Test await()
  
  func testAwaitWithResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise()
    // Test await().
    let result = promise.await()
    XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
    expectation.fulfill()
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  func testAwaitWithReject() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise(shouldReject: true)
    // Test await().
    let result = promise.await()
    XCTAssertTrue(result == nil, "Actual result = \(result); Expected result = nil")
    expectation.fulfill()
    // Wait for asynchronous result.
    waitExpectation()
  }
}

// MARK: - Convenience methods

private extension SwiftPromiseTests {
  
  func createPromise(shouldReject: Bool = false) -> Promise<String> {
    let promise = Promise<String> { (resolve, reject) in
      self.delayAsync {
        if (shouldReject) {
          reject(Self.error)
        } else {
          resolve(Self.result)
        }
      }
    }
    return promise
  }
  
  func delayAsync(_ closure: @escaping () -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + Self.asyncDelay, execute: closure)
  }
}
