import UIKit
import PlaygroundSupport
// Required to let async tasks continue after playground is done running
PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: - Utility functions

/// Takes a closure and runs it, this is for syntax sugar, so we can use ribbons to hide code
///
/// - parameter run:     Boolean that indicates if the closure should be run or not
/// - parameter closure: The closure to run
func snippet(_ run: Bool, closure: @escaping () -> Void) {
    if run {
        closure()
    }
}

// For estimating how long it took for a task to run
let date = Date()
func secondsRunning() -> String {
    "\(date.timeIntervalSinceNow * -1)"
}


// MARK: - Ficticious requests

/// request the user ID
///
/// - parameter completion: Completion block with the userId
func requestUserID(completion: @escaping (Int) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion(2)
    }
}

/// Given a user ID returns the name of that user
///
/// - parameter userId:     The userId for whom we want to request the name.
/// - parameter completion: Completion block with the name for the given userId
func requestName(for userId: Int, completion: @escaping (String) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion("name\(userId)")
    }
}

/// Given a user ID returns the email of that user
///
/// - parameter userId:     The userId for whom we want to request the name.
/// - parameter completion: Completion block with the email for the given userId
func requestEmail(for userId: Int, completion: @escaping (String) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion("\(userId)@\(userId).com")
    }
}

/// Given a user ID returns the balance of the user
///
/// - parameter userId:     The userId for whom we want to request the name.
/// - parameter completion: Completion block with the balance for the given userId
func requestBalance(for userId: Int, completion: @escaping (Int) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion(Int.random(in: 100...999))
    }
}

//MARK: - Direct approach creating a callback hell
snippet(false) {
    
    requestUserID { userId in
        requestName(for: userId) { name in
            requestEmail(for: userId) { email in
                requestBalance(for: userId) { balance in
                    print("Callback hell: \(name) - \(email) - \(balance) - \(secondsRunning())")
                }
            }
        }
    }
    
}

//MARK: - Approach using dispatch groups
snippet(false) {
    let group = DispatchGroup()                 // Dispatch group that keeps track of pending tasks
    
    var name: String = ""                       // Will eventually hold the real value
    var email: String = ""                      // Will eventually hold the real value
    var balance: Int = 0                        // Will eventually hold the real value
    
    group.enter()                               // We signal the group that we started an activity (requestUserID)
    requestUserID { userId in
        group.enter()                           // We signal the group that we started an activity (requestName)
        requestName(for: userId) { value in
            name = value                        // Update the local variable with the result
            group.leave()                       // Signal the group that a task has finished (requestName)
        }
        
        group.enter()                           // We signal the group that we started an activity (requestEmail)
        requestEmail(for: userId) { value in
            email = value                       // Update the local variable with the result
            group.leave()                       // Signal the group that a task has finished (requestEmail)
        }
        
        group.enter()                           // We signal the group that we started an activity (requestEmail)
        requestBalance(for: userId) { value in
            balance = value                     // Update the local variable with the result
            group.leave()                       // Signal the group that a task has finished (requestEmail)
        }
        
        group.leave()                           // Signal the group that a task has finished (requestUserID)
    }
    
    group.notify(queue: .main) {                // Closure executed once the group execution is done
        print("Dispatch group: \(name) - \(email) - \(balance) - \(secondsRunning())")
    }
}

// MARK: - Combine approach
import Combine
// This set holds onto the cancellables so they are allowed to continue running
// We need to store it at the global level to avoid it being deallocated once the snippets closure ends running
var cancellables: Set<AnyCancellable> = []

// Working with Futures and Deferred
snippet(false) {
    // We create a future. that in this example, never fails.
    // This future generates a random number between [1, 100] after 1 second
    let future = Future<Int, Never> { promise in                // A future has a promise that is nothing more than a completion closure like the ones we used before
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {   // Delay to mimic an asyncronous task
            let randomNumber = Int.random(in: 1...100)          // This random integer is our task that had to be performed asychronously
            promise(.success( randomNumber ))                   // We fulfil the promise by returning the value wrapped in a success message
        }
    }
    
    future.sink { value1 in                                     // We attach a closure that will execute once the future has produced it's value
        print("future 1: \(value1) - \(secondsRunning())")      // Printing the produced value
        
        future.sink { value2 in                                 // We attach a closure but as the future has already produced the value it will run almost inmediately
            print("future 2: \(value2) - \(secondsRunning())")  // Printing the produced value
        }
        .store(in: &cancellables)                               // We need to hold onto the cancellable otherwise it won't do anything. Storing them in a set of cancellables is an easy way to achieve that as long as the set lives for as long as required for the value to be produced
    }
    .store(in: &cancellables)                                   // We need to hold onto the cancellable otherwise it won't do anything. Storing them in a set of cancellables is an easy way to achieve that as long as the set lives for as long as required for the value to be produced
    
    // A Deferred executes a closure that returns a publisher every time someone subscribes to it.
    // If the closure creates a new publisher, then a new publiser is generated everytime
    let deferred = Deferred {
        Future<Int, Never> { promise in                         // We create a new future everytime
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                promise(.success( Int.random(in: 1...100) ))
            }
        }
    }
    
    deferred.sink { value1 in                                   // We attach a closure that will execute once the publisher returned by the deferred produces a value
        print("deferred 1: \(value1) - \(secondsRunning())")    // Printing the produced value

        deferred.sink { value2 in                               // We attach again to the same deferred, but the puclisher inside is new and different to the one before
            print("deferred 2: \(value2) - \(secondsRunning())")// Printing the produced value
        }
        .store(in: &cancellables)                               // We need to hold onto the cancellable otherwise it won't do anything. Storing them in a set of cancellables is an easy way to achieve that as long as the set lives for as long as required for the value to be produced
    }
    .store(in: &cancellables)                                   // We need to hold onto the cancellable otherwise it won't do anything. Storing them in a set of cancellables is an easy way to achieve that as long as the set lives for as long as required for the value to be produced
}

// Converting closure based functions into publishers
snippet(false) {
    func requestUserID_C() -> AnyPublisher<Int, Never> {
        Deferred {
            Future { promise in
                requestUserID() { id in
                    promise(.success(id))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func requestName_C(for userId: Int) -> AnyPublisher<String, Never> {
        Deferred {
            Future { promise in
                requestName(for: userId) { value in
                    promise(.success(value))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func requestEmail_C(for userId: Int) -> AnyPublisher<String, Never> {
        Deferred {
            Future { promise in
                requestEmail(for: userId) { value in
                    promise(.success(value))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func requestBalance_C(for userId: Int) -> AnyPublisher<Int, Never> {
        Future { promise in
            requestBalance(for: userId) { value in
                promise(.success(value))
            }
        }
        .eraseToAnyPublisher()
    }
    
    requestUserID_C()                                   // We take a publisher of userIds
        .sink { userId in                               // We attach a closure to execute when it produces a value
            requestName_C(for: userId)                  // We take the publisher for name
                .zip(requestEmail_C(for: userId),       // We "zip" it with the publisher of email
                     requestBalance_C(for: userId))     // We "zip" it with the publisher of balance
                .sink { name, email, balance in         // We attach a closure that will get the 3 values at once since they are "zipped" together
                    print("Combine: \(name) - \(email) - \(balance) - \(secondsRunning())")
                }
                .store(in: &cancellables)               // We need to store the cancellable for the zipped publishers otherwise nothing happens
        }
        .store(in: &cancellables)                       // We need to store the cancellable for the userId publisher otherwise nothing happens
}

// MARK: - Combine and sub publishers
snippet(false) {
    /// Returns a string representing the value delayed by the same ammount of seconds
    ///
    /// - parameter value: The interger to return as a string after `value` of seconds.
    func delayedString(for value: Int) -> AnyPublisher<String, Never> {
        Deferred {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(value)) {
                    promise(.success("\(value)"))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // A subject that can receives and emit integers
    let integerSubject = PassthroughSubject<Int, Never>()
    
    snippet(false) {
        integerSubject                              // A subject that can receives and emit integers
            .flatMap { value in                     // We treat it as a publisher an flatMap over it
                delayedString(for: value)           // We transform every event into a new publisher, as this new publisher only emits 1 event we are mapping events 1 to 1
            }
            .sink { value in                        // We attach a closure that will execute once per every event
                print("flatMap: \(value)")
            }
            .store(in: &cancellables)               // We need to hold onto the cancellable otherwise it won't do anything. Storing them in a set of cancellables is an easy way to achieve that as long as the set lives for as long as required for the value to be produced
    }
    
    snippet(false) {
        integerSubject                              // A subject that can receives and emit integers
            .map { value in                         // We treat it as a publisher an map over every event
                delayedString(for: value)           // We transform every event into a new publisher, as this new publisher only emits 1 event we are mapping events 1 to 1
            }
            .switchToLatest()                       // Switch to latest cancels any still running publisher that a previous event could have generated so only the most recent sub-publisher is active at a time
            .sink { value in                        // We attach a closure that will execute once per every event
                print("map + switchToLatest: \(value)")
            }
            .store(in: &cancellables)               // We need to hold onto the cancellable otherwise it won't do anything. Storing them in a set of cancellables is an easy way to achieve that as long as the set lives for as long as required for the value to be produced
    }
    
    print("Sending events to chainSubject")
    integerSubject.send(2)                          // Sending integer 2 into the pipe
    integerSubject.send(1)                          // Sending integer 1 into the pipe
    integerSubject.send(3)                          // Sending integer 3 into the pipe
}

// MARK: - Combine and timers
snippet(false) {
    Timer.publish(every: 1.0, on: .main, in: .default)  // Creates a publisher that emits every second
        .autoconnect()                                  // Starts the timer as soon as it has a subscriber
        .sink { date in                                 // Attaches a closure that will be executed on every event, in this case every time the timer fires
            print("Date: \(date)")
        }
        .store(in: &cancellables)                       // We need to hold onto the cancellable otherwise it won't do anything. Storing them in a set of cancellables is an easy way to achieve that as long as the set lives for as long as required for the value to be produced
}

snippet(false) {
    // A subject that can receives and emit doubles
    let doubleSubject = PassthroughSubject<Double, Never>()
    
    doubleSubject
        .map { delay in                                             // We map over each event changing the output from Double to Timer.Publisher
            Timer.publish(every: delay, on: .main, in: .default)    // Creates a publisher that emits every X seconds
                .autoconnect()                                      // Starts the timer as soon as it has a subscriber
        }
        .switchToLatest()                                           // This cancels any other publisher previously generated so any previous timer gets invalidated.
        .sink { date in                                             // Attaches a closure that will be executed on every event, in this case every time the timer fires
            print("Date: \(date)")
            doubleSubject.send(3)
        }
        .store(in: &cancellables)                                   // We need to hold onto the cancellable otherwise it won't do anything. Storing them in a set of cancellables is an easy way to achieve that as long as the set lives for as long as required for the value to be produced

    doubleSubject.send(1)                                           // We start the machinery by sending our first event.
}
