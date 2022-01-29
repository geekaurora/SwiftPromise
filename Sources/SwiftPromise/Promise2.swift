import Foundation

/**
 Promise2 library that manages asynchronous tasks elegantly.
 
 ### Usage
 
 1. then()/catch():
 ```
 let promise = Promise2<String> { (resolve, reject) in
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
 If `then()` returns a new Promise2, it will be executed correspondingly.
 
 2. await():
 ```
 let result = promise.await()
 print(result)
 ```
 
 3. all():
 ```
 let promises = [createPromise2(), createPromise2(), createPromise2()]
 
 Promise2.all(promises)
 .then { _ in
   print("Completed all promises successfully.")
 }.catch { error in
   print("Failed to execute promises. Error - \(error)")
 }
 ```
 */
public class Promise2<Result> {
  /// Resolve callback closure.
  public typealias Resolve = (Result?) -> Void
  /// Reject callback closure.
  public typealias Reject = (Error?) -> Void
  /// Execution closure.
  public typealias Execution = (@escaping Resolve, @escaping Reject) -> Void
  private let execution: Execution
  
  /// Result of execution.
  private var result: Result?
  /// Indicates whether result has been initialized.
  private var isResultInitialized = false
  /// Error of execution.
  private var error: Error?
  
  /// Then callback closure.
  // public typealias Then<T> = (T?) -> Promise2<T>?
  public typealias Then<T> = (T?) -> T?
  private var thenClosure: Then<Result>?
  /// Catch callback closure.
  public typealias Catch = (Error?) -> Void
  private var catchClosure: Catch?
  
  /// Semaphore for async/await signal.
  private var semaphore: DispatchSemaphore?
  
  public static var allPromise2sSuccessString: String {
    return "Succeed to execute all promises."
  }
  
  /// Initialize with `execution` closure.
  /// Call `resolve()` on success, and call `reject()` on failure.
  public init(_ execution: @escaping Execution) {
    self.execution = execution
  }
  
  /// `then` function that will be called on `resolve()`.
  @discardableResult
  public func then(_ thenClosure: @escaping Then<Result>) -> Promise2<Result> {
    // Store `then`.
    self.thenClosure = thenClosure
    // Start `execution`.
    execution(resolve, reject)
    return self
  }
  
  /// `catch` function that will be called on `reject()`.
  @discardableResult
  public func `catch`(_ catchClosure: @escaping Catch) -> Promise2<Result> {
    self.catchClosure = catchClosure
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
  public static func all(_ promises: [Promise2]) -> Promise2<String> {
    // 0. Create promise that executes all `promises`.
    let allPromise2 = Promise2<String> { (resolve, reject) in
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
        resolve(allPromise2sSuccessString)
      }
    }
    
    // 4. Return `allPromise2`.
    return allPromise2
  }
}

// MARK: - Resolve / Reject

private extension Promise2 {
  /// Function will be called on execution success.
  func resolve(_ result: Result?) {
    if !isResultInitialized {
      // Only update `self.result` by `resolve()` for the first time, after that `self.result` will be updated by each `then` block.
      self.result = result
      isResultInitialized = true
    }

    if !signalIfNeeded() {
      // Call `then` with `self.result`.
      //
      // - Note: If `then()` returns a new result, update self's `result` - which will be used for the next `then()`.
      self.result = thenClosure?(self.result)
      // newPromise2.execution(resolve, reject)
    }
  }
  
  /// Function will be called on execution failure.
  func reject(_ error: Error?) {
    if !signalIfNeeded() {
      // Call `then` with `error`.
      catchClosure?(error)
    }
  }
}

// MARK: - Signal

private extension Promise2 {
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
