**CAUTION: This library has been abandoned and replaced by a new implementation [`Flow`](https://github.com/eonil/flow.swift).**


Step
====
Hoon H.
2016.07.05

Introduction
------------
A continuation-based corutine-like flow control.
This library is mainly inspired from Bolts/BoltsSwift. Mainly written due to slow update of BoltsSwift for Swift3.

This library provides these in addition to BoltsSwift.

- No ambiguous error and cancellation by default.
- Optional opt-in to error-tolerable continuation.
- Always checks for unhandled error at the end of continuation flow.
- Allows continuation from a continuation only once. (crash on trial to continue multiple times)
- Name of continuation is not `Task` to avoid name ambiguity with `Foundation.Task` in Swift 3.

Getting Started
---------------
It's almost same with Bolts `Task`.

    let s = Step(11).step{$0 * 2}.step{$0 + 1}.step{print($0)}
    // `23` will be printed.

To make an asynchronous stepping, do something like this.

    let s = getSomeAsyncStepping()
    let sc = SteppingController<Int>()
    s.step(.specific(DispatchQueue.global)) {
        sc.complete(36)
    }

Design Choices and Reasons
--------------------------
Bolts is a great library, but it has too much by default, and lacks some safety checks.
Because Bolts employs failure(error) and cancellation by default, it's sometimes vague to write
some logics that does not play well with concept of cancellation or failure. This library provides clean 
slated continuation device `Stepping` which does not have such extras by default. `Stepping` continuation 
does not have concept of failure or cancellation, so it never fails, and never cancels. It always advances,
and eventually terminates if you dont continue anymore.

Anyway, sometimes we want error-hadling, so this library also provides additional continuation device
`TolerantStepping` which provides error-skipping execution flow. With `TolerantStepping`, some of your
continuation can throw some error, and then execution flow will skip any further executions from there
until it meets a proper error handling continuation. Furthermore, `TolerantStepping` cannot terminate.
Which means you always have to switch to `Stepping` continuation. This is an intentional design to 
force you to handle every errors. 

Also, because two continuations are distinct by types, compiler can check validity of continuations
statically.
