import Foundation

public class Promise {
  public typealias Input = Any
  public typealias Result = Any
  
  /// Resolve callback closure.
  public typealias Resolve = (Input?) -> Void
  /// Reject callback closure.
  public typealias Reject = (Error?) -> Void
  /// Pre-execution closure: the real preExecution will be when resolve() / reject() gets called.
  public typealias Execution = (@escaping Resolve, @escaping Reject) -> Void
  private let preExecution: Execution
  
  /// Error of preExecution.
  private var error: Error?
  
  /// Then callback closure.
  public typealias Then<T, U> = (T?) -> U?
  
  /// Array of chaining then closures.
  /// - Note: RootPromise maintains all `thenClosures`, instead of each Promise maintaining its own.
  private var thenClosures = [Then<Input, Any>]()
  private var currentThenIndex = 0

  /// Catch callback closure.
  public typealias Catch = (Error?) -> Void
  private var catchClosure: Catch?
  
  /// Semaphore for async/await signal.
  private var semaphore: DispatchSemaphore?
  
  private var externalInput: Input?
  private var nextPromise: Promise?
  
  public static var allPromisesSuccessString: String {
    return "Succeed to execute all promises."
  }
  
  /// Initialize with `preExecution` closure.
  /// Call `resolve()` on success, and call `reject()` on failure.
  public init(_ preExecution: @escaping Execution) {
    self.preExecution = preExecution
  }
  
  /// `then` function that will be called on `resolve()`: `then()` returns Promise.
  @discardableResult
  public func then(_ thenClosure: @escaping Then<Input, Promise>) -> Promise {
    // 1. Store `then`.
//    self.thenClosure = { (input) in
//      return thenClosure(input as! Input)
//    }
    
    let nextPromise = thenClosure(nil)
    
    // Start pre-preExecution `preExecution`: the real preExecution will be when resolve() / reject() gets called.
    preExecution(resolve, reject)
    
    return self
  }
  
  /// `then` function that will be called on `resolve()`.
//  //public func then<Output>(_ thenClosure: @escaping Then<Input, Output>) -> Promise<Output> {
//  public func then<Output>(_ thenClosure: @escaping Then<Input, Output>) -> Promise<Output> {
//    // 1. Store `then`.
//    self.thenClosure = { (input) in
//      return thenClosure(input as! Input)
//    }
//
//    // * New Promise: its `.then()` will be set externally.
//    let nextPromise = Promise<Output> { (resolve, reject) in }
//    self.nextPromise = nextPromise as! Promise<Any>
//
//    // 2. Trigger preExecution.
//    if self.externalInput != nil {
//      // Resolve automatically with previousResult: for non-first promise.
//      resolve(self.externalInput)
//    } else {
//      // Start pre-preExecution `preExecution`: the real preExecution will be when resolve() / reject() gets called.
//      preExecution(resolve, reject)
//    }
//
//    // 3. Return new Promise.
//    return nextPromise
//    // return self
//  }
//
  /// `catch` function that will be called on `reject()`.
  @discardableResult
  public func `catch`(_ catchClosure: @escaping Catch) -> Promise {
    self.catchClosure = catchClosure
    return self
  }
  
}

// MARK: - Resolve / Reject

private extension Promise {
  /// Function will be called on preExecution success.
  func resolve(_ input: Input?) {
    // Use `self.externalInput` if exists, otherwise use `input`.
    // let nextInput = thenClosure?(self.externalInput ?? input)
    let nextInput = input
    
    // Set the input for `nextPromise`.
    nextPromise?.externalInput = nextInput
    
    // Call nextPromise's preExecution: prepare.
    nextPromise?.preExecution(nextPromise!.resolve, nextPromise!.reject)
    
    // No need to call nextPromise: will be called in `then()` of nextPromise.
    // nextPromise?.resolve(nextInput)
  }
  
  /// Function will be called on preExecution failure.
  func reject(_ error: Error?) {
    // Call `then` with `error`.
    catchClosure?(error)
  }
}
