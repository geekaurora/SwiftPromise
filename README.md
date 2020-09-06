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
  print("Completed all promises.")
}.catch { error in
  print("Failed to execute the promises. Error - \(error).")
}
```
