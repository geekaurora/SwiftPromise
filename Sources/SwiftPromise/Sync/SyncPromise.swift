import Foundation

/**
 The promise that supports sync mode  chaining`then()` closures.
 
 `then()` closure: returns Value, instead of Promise.
 */
public class SyncPromise<Input> {
  public typealias Result = Any
  
  /// Resolve callback closure.
  public typealias Resolve = (Input?) -> Void
  /// Reject callback closure.
  public typealias Reject = (Error?) -> Void
  /// Execution closure: the real execution of SyncPromise.
  public typealias Execution = (@escaping Resolve, @escaping Reject) -> Void
  private let execution: Execution
  
  /// Error of execution.
  private var error: Error?
  
  /// Then callback closure.
  // public typealias Then<T> = (T?) -> SyncPromise<T>?
  public typealias Then<T, U> = (T?) -> U?
  private var thenClosure: Then<Input, Any>?
  /// Catch callback closure.
  public typealias Catch = (Error?) -> Void
  private var catchClosure: Catch?
  
  /// Semaphore for async/await signal.
  private var semaphore: DispatchSemaphore?
  
  private var externalInput: Input?
  private var nextPromise: SyncPromise<Any>?
  
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
  //public func then<Output>(_ thenClosure: @escaping Then<Input, Output>) -> SyncPromise<Output> {
  //public func then<Output>(_ thenClosure: @escaping Then<Input, Output>) -> SyncPromise<Any> {
  public func then(_ thenClosure: @escaping Then<Input, Any>) -> SyncPromise<Any> {
  // Store `then`.
    self.thenClosure = thenClosure
    
    // * Return new SyncPromise: its `.then()` will be set externally.
    nextPromise = SyncPromise<Any> { (resolve, reject) in }

    if self.externalInput != nil {
      // Resolve automatically with previousResult: for non-first promise.
      resolve(self.externalInput)
    } else {
      // Start pre-execution `execution`: the real execution will be when resolve() / reject() gets called.
      execution(resolve, reject)
    }
    
    return nextPromise!
    // return self
  }
  
  /// `catch` function that will be called on `reject()`.
  @discardableResult
  public func `catch`(_ catchClosure: @escaping Catch) -> SyncPromise<Input> {
    self.catchClosure = catchClosure
    return self
  }
  
  /// Execute synchronously on the current thread and return result.
  ///
  /// - Note: execution shouldn't be on the same thread as `await()`, otherwise it will cause deadlock.
//  public func await() -> Result? {
//    // Start `execution`.
//    execution(resolve, reject)
//    // Wait on the current thread until get result or error.
//    waitForSignal()
//    return self.result
//  }
  
  /// Returns when all `promises` complete.
//  public static func all(_ promises: [SyncPromise]) -> SyncPromise<String> {
//    // 0. Create promise that executes all `promises`.
//    let allPromise = SyncPromise<String> { (resolve, reject) in
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

private extension SyncPromise {
  /// Function will be called on execution success.
  func resolve(_ input: Input?) {
    // Use `self.externalInput` if exists, otherwise use `input`.
    let nextInput = thenClosure?(self.externalInput ?? input)
    
    // Set the input for `nextPromise`.
    nextPromise?.externalInput = nextInput
    
    // Call nextPromise: No need - will be called in `then()` of nextPromise.
    // nextPromise?.resolve(nextInput)
    // nextPromise.execution(resolve, reject)
    
    //self.result = thenClosure?(self.result)
  }
  
  /// Function will be called on execution failure.
  func reject(_ error: Error?) {
    // Call `then` with `error`.
    catchClosure?(error)
  }
}

// MARK: - Signal

private extension SyncPromise {
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
