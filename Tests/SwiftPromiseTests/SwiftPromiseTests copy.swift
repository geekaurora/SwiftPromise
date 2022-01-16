import XCTest
import CZTestUtils
@testable import SwiftPromise

final class SwiftPromiseTests2: XCTestCase {
  static let result = "PromiseResult"
  static let chainingThenPromiseResult = "chainingThenPromiseResult"
  static let error: Error? = NSError(domain: "Error", code: 999, userInfo: nil)
  static let asyncDelay: TimeInterval = 0.1
  static let fulfillWaitInterval: TimeInterval = 20
  
}

// MARK: - Convenience methods

private extension SwiftPromiseTests2 {

  func createPromise(result: String = SwiftPromiseTests.result, shouldReject: Bool = false) -> Promise<String> {
    let promise = Promise<String> { (resolve, reject) in
      self.delayAsync {
        if (shouldReject) {
          reject(Self.error)
        } else {
          resolve(result)
        }
      }
    }
    return promise
  }
  
  func delayAsync(_ closure: @escaping () -> Void) {
    closure()
    // DispatchQueue.global().asyncAfter(deadline: .now() + Self.asyncDelay, execute: closure)
  }
}
