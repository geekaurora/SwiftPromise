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
public class Promise<Input> {
  public typealias Result = Any
  
  /// Resolve callback closure.
  public typealias Resolve = (Input?) -> Void
  /// Reject callback closure.
  public typealias Reject = (Error?) -> Void
  /// Pre-execution closure: the real preExecution will be when resolve() / reject() gets called.
  public typealias Execution = (@escaping Resolve, @escaping Reject) -> Void
  private let preExecution: Execution
  
  /// Input of preExecution.
  // private var result: Result?
  /// Indicates whether result has been initialized.
  private var isResultInitialized = false
  /// Error of preExecution.
  private var error: Error?
  
  /// Then callback closure.
  // public typealias Then<T> = (T?) -> Promise<T>?
  public typealias Then<T, U> = (T?) -> U?
  private var thenClosure: Then<Input, Any>?
  /// Catch callback closure.
  public typealias Catch = (Error?) -> Void
  private var catchClosure: Catch?
  
  /// Semaphore for async/await signal.
  private var semaphore: DispatchSemaphore?
  
  private var externalInput: Input?
  private var nextPromise: Promise<Any>?
  
  public static var allPromisesSuccessString: String {
    return "Succeed to execute all promises."
  }
  
  /// Initialize with `preExecution` closure.
  /// Call `resolve()` on success, and call `reject()` on failure.
  public init(_ preExecution: @escaping Execution) {
    self.preExecution = preExecution
  }
  
  /// `then` function that will be called on `resolve()`.
  @discardableResult
  //public func then<Output>(_ thenClosure: @escaping Then<Input, Output>) -> Promise<Output> {
  public func then(_ thenClosure: @escaping Then<Input, Any>) -> Promise<Any> {
    // 1. Store `then`.
    self.thenClosure = thenClosure
    
    // * New Promise: its `.then()` will be set externally.
    nextPromise = Promise<Any> { (resolve, reject) in }
    
    // 2. Trigger preExecution.
    if self.externalInput != nil {
      // Resolve automatically with previousResult: for non-first promise.
      resolve(self.externalInput)
    } else {
      // Start pre-preExecution `preExecution`: the real preExecution will be when resolve() / reject() gets called.
      preExecution(resolve, reject)
    }
    
    // 3. Return new Promise.
    return nextPromise!
    // return self
  }
  
  /// `catch` function that will be called on `reject()`.
  @discardableResult
  public func `catch`(_ catchClosure: @escaping Catch) -> Promise<Input> {
    self.catchClosure = catchClosure
    return self
  }
  
  /// Execute synchronously on the current thread and return result.
  ///
  /// - Note: preExecution shouldn't be on the same thread as `await()`, otherwise it will cause deadlock.
  //  public func await() -> Result? {
  //    // Start `preExecution`.
  //    preExecution(resolve, reject)
  //    // Wait on the current thread until get result or error.
  //    waitForSignal()
  //    return self.result
  //  }
  
  /// Returns when all `promises` complete.
  //  public static func all(_ promises: [Promise]) -> Promise<String> {
  //    // 0. Create promise that executes all `promises`.
  //    let allPromise = Promise<String> { (resolve, reject) in
  //      let dispatchGroup = DispatchGroup()
  //
  //      // 1. Loop through all promises and execute.
  //      for promise in promises {
  //        dispatchGroup.enter()
  //        promise.then { res in
  //          dispatchGroup.leave()
  //          return nil
  //        }.catch { err in
  //          // 2. Exit on any failure of promises
  //          reject(err)
  //          return
  //        }
  //      }
  //
  //      // 3. Notify after all `promises` complete.
  //      dispatchGroup.notify(queue: .main) {
  //        resolve(allPromisesSuccessString)
  //      }
  //    }
  //
  //    // 4. Return `allPromise`.
  //    return allPromise
  //  }
  
}

// MARK: - Resolve / Reject

private extension Promise {
  /// Function will be called on preExecution success.
  func resolve(_ input: Input?) {
    // Use `self.externalInput` if exists, otherwise use `input`.
    let nextInput = thenClosure?(self.externalInput ?? input)
    
    // Set the input for `nextPromise`.
    nextPromise?.externalInput = nextInput
    
    // Call nextPromise: No need - will be called in `then()` of nextPromise.
    // nextPromise?.resolve(nextInput)
    // nextPromise.preExecution(resolve, reject)
    
    //self.result = thenClosure?(self.result)
  }
  
  /// Function will be called on preExecution failure.
  func reject(_ error: Error?) {
    // Call `then` with `error`.
    catchClosure?(error)
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
