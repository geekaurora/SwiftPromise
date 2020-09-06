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
   .catch{ error in
     print(error)
   }
```

2. await():


```
   let result = promise.await()
   print(result)
```
