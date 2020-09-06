import Foundation

/**
 Promise library that manages asynchronous tasks elegantly.
 
 ### Usage
 
 1. then()/catch():
 ```
    let promise = Promise<String> { (resolve, reject) in
      self.delayAsync {
        resolve("result")
      }
    }
    promise.then { result in
      print(result)
    }
    .catch{ error in
      print(error)
    }
 ```
 
 2. await():
 ```
    let result = promise.await()
    print(result)
 ```
 */
public class Promise<Result> {
  /// Resolve callback closure.
  public typealias Resolve = (Result?) -> Void
  /// Reject callback closure.
  public typealias Reject = (Error?) -> Void
  /// Execution closure.
  public typealias Execution = (@escaping Resolve, @escaping Reject) -> Void
  private let execution: Execution
  
  /// Result of execution.
  private var result: Result?
  /// Error of execution.
  private var error: Error?
  
  /// Then callback closure.
  public typealias Then = (Result?) -> Void
  private var then: Then?
  /// Catch callback closure.
  public typealias Catch = (Error?) -> Void
  private var `catch`: Catch?
  
  /// The semaphore for async/await signal.
  private var semaphore: DispatchSemaphore?
  
  /// Initialize with `execution` closure.
  /// Call `resolve()` on success, and call `reject()` on failure.
  public init(_ execution: @escaping Execution) {
    self.execution = execution
  }
  
  /// `then` function that will be called on `resolve()`.
  @discardableResult
  public func then(_ then: @escaping Then) -> Promise<Result> {
    // Store `then`.
    self.then = then
    // Start `execution`.
    execution(resolve, reject)
    return self
  }
  
  /// `catch` function that will be called on `reject()`.
  @discardableResult
  public func `catch`(_ `catch`: @escaping Catch) -> Promise<Result> {
    self.`catch` = `catch`
    return self
  }
  
  /// Execute synchronously on the current thread and return result.
  ///
  /// - Note: execution shouldn't be on the same thread, otherwise it will cause deadlock.
  public func await() -> Result? {
    // Start `execution`.
    execution(resolve, reject)
    
    // Wait on the current thread until get result or error.
    waitForSignal()
    return self.result
  }
}

// MARK: - Resolve / Reject

private extension Promise {
  /// Function will be called on execution success.
  func resolve(_ result: Result?) {
    // Call `then` with `result`.
    self.result = result
    if (!signalIfNeeded()) {
      then?(result)
    }
  }
  
  /// Function will be called on execution failure.
  func reject(_ error: Error?) {
    // Call `then` with `error`.
    if (!signalIfNeeded()) {
      `catch`?(error)
    }
  }
}

// MARK: - Signal

private extension Promise {
  func waitForSignal() {
    semaphore = DispatchSemaphore(value: 0)
    semaphore?.wait()
  }
  
  func signalIfNeeded() -> Bool {
    let hasLock = (semaphore != nil)
    semaphore?.signal()
    semaphore = nil
    return hasLock
  }
}
