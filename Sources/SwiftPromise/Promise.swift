import Foundation
import CZUtils

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
  private var thenClosures = [Then<Input, Promise>]()
  
  /// The index of the current executing promise in the chaining promises.
  private var currPromiseIndex = 0

  /// Catch callback closure.
  public typealias Catch = (Error?) -> Void
  private var catchClosure: Catch?
  
  /// The root Promise that maintains the chaining then() closures.
  /// For async then() closures, we can’t return promise generated with `then(input)` in the current runloop, because `input` is unknown before executing the previous async promise.
  /// We only know`input` after the  prev async Promise resolves, so root Promise is needed to maintain and cache the chaining then() closures for generating promises later on.
  private weak var rootPromise: Promise?
  
  /// The result of the previous then() closure.
  private var prevThenResult: Input?
  
  /// The next promise to execute.
  private var nextPromise: Promise?
  
  /// Initialize with `preExecution` closure.
  /// Call `resolve()` on success, and call `reject()` on failure.
  ///
  /// - Parameters:
  ///   - rootPromise: rootPromise is required for non-first promise that is generated in then() closure.
  ///   - preExecution: call `resolve()` on success, and call `reject()` on failure.
  public init(root rootPromise: Promise?,
              _ preExecution: @escaping Execution) {
    self.rootPromise = rootPromise
    self.preExecution = preExecution
    
    if self.rootPromise == nil {
      // Set `rootPromise` with self if it's nil, which will be held weak reference.
      self.rootPromise = self
    }
  }
  
  /// `thenClosure` that will be called by `resolve()`: `then()` returns Promise.
  @discardableResult
  public func then(_ thenClosure: @escaping Then<Input, Promise>) -> Promise {
    // 1. Store `thenClosure`.
    let hasQueuedThenClosure = rootPromise!.hasQueuedThenClosure()
    rootPromise?.enqueueThenClosure(thenClosure)
    
    // 2. preExecution(): if has no thenClosure in queue - no previous resolve() left.
    // The remaining promises will be prepared in its prev promise's resolve().
    // `preExecution`: just prepare - the real execution will be when resolve() / reject() gets called.
    if !hasQueuedThenClosure {
      // Should call `resolveSync()` explicitly.
      preExecution(resolveSync, reject)
    }
    
    return self
  }
  
  /// `catch` function that will be called on `reject()`.
  @discardableResult
  public func `catch`(_ catchClosure: @escaping Catch) -> Promise {
    self.catchClosure = catchClosure
    return self
  }
  
  // MARK: - RootPromise
  
  func hasQueuedThenClosure() -> Bool {
    return thenClosures.count > 0
  }
  
  func enqueueThenClosure(_ thenClosure: @escaping Then<Input, Promise>) {
    thenClosures.append(thenClosure)
  }
  
  func dequeNextThenClosures() -> Then<Input, Promise>? {
    guard hasQueuedThenClosure() else {
      return nil
    }
    let nextThenClosure = thenClosures.removeFirst()
    currPromiseIndex += 1
    return nextThenClosure
  }
  
}


// MARK: - Resolve / Reject

private extension Promise {
  /// Function will be called on preExecution success.
  /// resolve(): completion with the current result.
  func resolve(_ result: Input?) {
    _resolve(result)
  }
  
  func resolveSync(_ result: Input?) {
    _resolve(result, isSync: true)
  }
  
  func _resolve(_ result: Input?, isSync: Bool = false) {
    var nextResult = result
    if isSync {
      // If `preExecution()` is called from `then()` directly, should use `rootPromise?.prevThenResult` as nextResult if exists.
      nextResult = rootPromise?.prevThenResult ?? result
    }
    // Should cache `result` as `prevThenResult`, because in sync mode: when current promise resolve() result, the next thenClosure() isn't set yet.
    rootPromise?.prevThenResult = result
    
    guard let nextThenClosure = rootPromise?.dequeNextThenClosures() else {
      dbgPrintWithFunc(self, "Completed all promises! currPromiseIndex = \(currPromiseIndex), thenClosures.count = \(thenClosures.count)")
      return
    }
    
    // Generate nextPromise: call `nextThenClosure()` with `nextResult`.
    nextPromise = nextThenClosure(nextResult)
    
    // Call nextPromise's preExecution: prepare.
    if let nextPromise = self.nextPromise {
      nextPromise.preExecution(nextPromise.resolve, nextPromise.reject)
    }
    
    // No need to call nextPromise's resolve(): it will be called by nextPromise itself.
    // nextPromise?.resolve(nextInput)    
  }
  
  /// Function will be called on preExecution failure.
  func reject(_ error: Error?) {
    // Call `then` with `error`.
    catchClosure?(error)
  }
}
