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
 promise
 .then { result in
  print(result)
 }
 .catch { error in
  print(error)
 }
 ```
 If `then()` returns a new Promise, it will be executed correspondingly.
 
 2. await():
 ```
 let result = promise.await()
 print(result)
 ```
 
 3. all():
 ```
 let promises = [createPromise(), createPromise(), createPromise()]
 
 Promise.all(promises)
 .then { _ in
   print("Completed all promises successfully.")
 }.catch { error in
   print("Failed to execute promises. Error - \(error)")
 }
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
  // public typealias Then<T> = (T?) -> Promise<T>?
  public typealias Then<T> = (T?) -> T?
  private var then: Then<Result>?
  /// Catch callback closure.
  public typealias Catch = (Error?) -> Void
  private var `catch`: Catch?
  
  /// Semaphore for async/await signal.
  private var semaphore: DispatchSemaphore?
  
  public static var allPromisesSuccessString: String {
    return "Succeed to execute all promises."
  }
  
  /// Initialize with `execution` closure.
  /// Call `resolve()` on success, and call `reject()` on failure.
  public init(_ execution: @escaping Execution) {
    self.execution = execution
  }
  
  /// `then` function that will be called on `resolve()`.
  @discardableResult
  public func then(_ then: @escaping Then<Result>) -> Promise<Result> {
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
  /// - Note: execution shouldn't be on the same thread as `await()`, otherwise it will cause deadlock.
  public func await() -> Result? {
    // Start `execution`.
    execution(resolve, reject)
    // Wait on the current thread until get result or error.
    waitForSignal()
    return self.result
  }
  
  /// Returns when all `promises` complete.
  public static func all(_ promises: [Promise]) -> Promise<String> {
    // 0. Create promise that executes all `promises`.
    let allPromise = Promise<String> { (resolve, reject) in
      let dispatchGroup = DispatchGroup()
      
      // 1. Loop through all promises and execute.
      for promise in promises {
        dispatchGroup.enter()
        promise.then { res in
          dispatchGroup.leave()
          return nil
        }.catch { err in
          // 2. Exit on any failure of promises
          reject(err)
          return
        }
      }
      
      // 3. Notify after all `promises` complete.
      dispatchGroup.notify(queue: .main) {
        resolve(allPromisesSuccessString)
      }
    }
    
    // 4. Return `allPromise`.
    return allPromise
  }
}

// MARK: - Resolve / Reject

private extension Promise {
  /// Function will be called on execution success.
  func resolve(_ result: Result?) {
    if self.result == nil {
      self.result = result
    }

    if !signalIfNeeded() {
      // Call `then` with `self.result`.
      //
      // - Note: If `then()` returns a new result, update self's `result` - which will be used for the next `then()`.
      self.result = then?(self.result)
      // newPromise.execution(resolve, reject)
    }
  }
  
  /// Function will be called on execution failure.
  func reject(_ error: Error?) {
    if !signalIfNeeded() {
      // Call `then` with `error`.
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
    let shouldSendSignal = (semaphore != nil)
    semaphore?.signal()
    semaphore = nil
    return shouldSendSignal
  }
}
