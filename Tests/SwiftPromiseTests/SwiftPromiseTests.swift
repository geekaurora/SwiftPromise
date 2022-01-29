import XCTest
import CZUtils
import CZTestUtils
@testable import SwiftPromise

final class SwiftPromiseTests: XCTestCase {
  static let result = "PromiseResult"
  static let firstThenPromiseResult = "firstThenPromiseResult"
  static let secondThenPromiseResult = "secondThenPromiseResult"
  static let error: Error? = NSError(domain: "Error", code: 999, userInfo: nil)
  static let asyncDelay: TimeInterval = 0.01
  static let fulfillWaitInterval: TimeInterval = 30
  
  // MARK: - Test resolve() / reject()
  
  func testSingleThenResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise(shouldAsync: false)
    
    promise
      .then { (result) -> Promise in
        return Promise(root: promise) { (resolve, reject) in
          XCTAssertTrue(result as! String == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
          
          // Call resolve() with the result for the next Promise
          resolve(Self.firstThenPromiseResult)
          expectation.fulfill()
        }
        
      }
    
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  func testSingleThenResolveAsynchronously() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise(shouldAsync: true)
    
    promise
      .then { (result) -> Promise in
        return Promise(root: promise) { (resolve, reject) in
          XCTAssertTrue(result as! String == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
          
          // Call resolve() with the result for the next Promise
          resolve(Self.firstThenPromiseResult)
          expectation.fulfill()
        }
        
      }
    
    // Wait for asynchronous result.
    waitExpectation()
  }
  
  /**
   Test chaining multitple `then` - returns Promise.
   */
  func testChainingThenResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    
    let promise = createPromise(shouldAsync: false)
    promise
      .then { (result) -> Promise in
        return Promise(root: promise) { (resolve, reject) in
          dbgPrint("[Debug] Finished the first then().")
          XCTAssertEqual(result as! String, Self.result)
          
          resolve(Self.firstThenPromiseResult)
        }
      }
      .then { (result) -> Promise in
        return Promise(root: promise) { (resolve, reject) in
          dbgPrint("[Debug] Finished the first then().")
          XCTAssertEqual(result as! String, Self.firstThenPromiseResult)
          
          resolve(Self.secondThenPromiseResult)
          expectation.fulfill()
        }
      }
    
    waitExpectation()
  }
  
}

// MARK: - Convenience methods

private extension SwiftPromiseTests {
  
  func createPromise(shouldAsync: Bool = true, shouldReject: Bool = false) -> Promise {
    let promise = Promise(root: nil) { (resolve, reject) in
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
      // DispatchQueue.global().asyncAfter(deadline: .now() + Self.asyncDelay, execute: closure)
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.asyncDelay, execute: closure)
    } else {
      closure()
    }
  }
}
