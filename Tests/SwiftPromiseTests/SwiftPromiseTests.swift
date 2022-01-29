import XCTest
import CZTestUtils
@testable import SwiftPromise

final class SwiftPromiseTests: XCTestCase {
  static let result = "PromiseResult"
  static let firstThenPromiseResult = "firstThenPromiseResult"
  static let secondThenPromiseResult = "secondThenPromiseResult"
  static let error: Error? = NSError(domain: "Error", code: 999, userInfo: nil)
  static let asyncDelay: TimeInterval = 0.1
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
  
  /**
   Test chaining multitple `then` - returns Promise.
   */
  func testChainingThenResolve() {
    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
    // Init promise.
    let promise = createPromise(shouldAsync: false)
    
    promise
      .then { (result) -> Promise in
        return Promise(root: promise) { (resolve, reject) in
          XCTAssertTrue(result as! String == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
          
          // Call resolve() with the result for the next Promise.
          resolve(Self.firstThenPromiseResult)
        }
      }
      .then { (result) -> Promise in
        return Promise(root: promise) { (resolve, reject) in
          XCTAssertTrue(result as! String == Self.firstThenPromiseResult, "Actual result = \(result); Expected result = \(Self.result)")
          
          // Call resolve() with the result for the next Promise.
          resolve(Self.secondThenPromiseResult)
          expectation.fulfill()
        }
        
        // Wait for asynchronous result.
        waitExpectation()
      }
  }
  
//  func testChainingThenResolve() {
//    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
//    // Init promise.
//    let promise = createPromise(shouldAsync: false)
//
//    // Test chaining then().
//    promise
//      .then { (result) -> Promise<String> in
//        return Promise<String> { (resolve, reject) in
//          XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
//
//          // Call resolve() with the result for the next Promise
//          resolve(Self.firstThenPromiseResult)
//          expectation.fulfill()
//        }
//
//      }
//    // * Note: next then() will call the same promise, as prev then() method returns `self`.
////      .then { (result) -> String? in
////        XCTAssertEqual(result as! String, Self.chainingThenPromiseResult)
////        expectation.fulfill()
////        return nil
////      }
//
//    // Wait for asynchronous result.
//    waitExpectation()
//  }
  
  
//  /**
//   Test chaining multitple `then` - returns value.
//   */
//  func testChainingThenResolve() {
//    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
//    // Init promise.
//    let promise = createPromise(shouldAsync: false)
//
//    // Test chaining then().
//    promise
//      .then { (result) -> String? in
//        print("First then")
//        XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
//        return Self.chainingThenPromiseResult
//      }
//    // * Note: next then() will call the same promise, as prev then() method returns `self`.
//      .then { (result) -> String? in
//        XCTAssertEqual(result as! String, Self.chainingThenPromiseResult)
//        expectation.fulfill()
//        return nil
//      }
//
//    // Wait for asynchronous result.
//    waitExpectation()
//  }

//  func testReject() {
//    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
//    // Init promise.
//    let promise = createPromise(shouldReject: true)
//
//    // Test catch().
//    promise.then { result in
//      XCTAssert(false, "then() shouldn't be called.")
//      return nil
//    }
//    .catch { error in
//      XCTAssertTrue(error as AnyObject === Self.error as AnyObject , "Actual result = \(error); Expected result = \(Self.error)")
//      expectation.fulfill()
//    }
//    // Wait for asynchronous result.
//    waitExpectation()
//  }
//

//
//  // MARK: - Test all()
//
//  func testAllPromisesResolve() {
//    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
//    // Init promise.
//    let promises = [createPromise(), createPromise()]
//
//    // Test then().
//    Promise.all(promises).then { (result) in
//      XCTAssertTrue(
//        result == Promise<Any>.allPromisesSuccessString,
//        "Actual result = \(result); Expected result = \(Promise<Any>.allPromisesSuccessString)")
//      expectation.fulfill()
//      return nil
//    }
//    // Wait for asynchronous result.
//    waitExpectation()
//  }
//
//  func testAllPromisesReject() {
//    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
//    // Init promise.
//    let promises = [createPromise(), createPromise(), createPromise(shouldReject: true)]
//
//    // Test then().
//    Promise.all(promises).then { _ in
//      XCTAssertTrue(false, "then() shouldn't be called.")
//      return nil
//    }.catch { error in
//      XCTAssertTrue(error as AnyObject === Self.error as AnyObject , "Actual result = \(error); Expected result = \(Self.error)")
//      expectation.fulfill()
//    }
//    // Wait for asynchronous result.
//    waitExpectation()
//  }
//
//  // MARK: - Test await()
//
//  func testAwaitWithResolve() {
//    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
//    // Init promise.
//    let promise = createPromise()
//    // Test await().
//    let result = promise.await()
//    XCTAssertTrue(result == Self.result, "Actual result = \(result); Expected result = \(Self.result)")
//    expectation.fulfill()
//    // Wait for asynchronous result.
//    waitExpectation()
//  }
//
//  func testAwaitWithReject() {
//    let (waitExpectation, expectation) = CZTestUtils.waitWithInterval(Self.fulfillWaitInterval, testCase: self)
//    // Init promise.
//    let promise = createPromise(shouldReject: true)
//    // Test await().
//    let result = promise.await()
//    XCTAssertTrue(result == nil, "Actual result = \(result); Expected result = nil")
//    expectation.fulfill()
//    // Wait for asynchronous result.
//    waitExpectation()
//  }
}

// MARK: - Convenience methods

private extension SwiftPromiseTests {

  func createPromise(shouldAsync: Bool = true, shouldReject: Bool = false) -> Promise {
    let promise = Promise { (resolve, reject) in
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
