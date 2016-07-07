//
//  SteppingCore.swift
//  Step
//
//  Created by Hoon H. on 2016/07/04.
//  Copyright © 2016 Eonil. All rights reserved.
//

typealias SteppingContinuation<T> = ((T) -> ())

enum SteppingState<T> {
    /// Stepping is not scheduled or completed.
    case unscheduledAndUnresolved
    case unscheduledButResolved(T)
    case unresolvedButScheduled(SteppingContinuation<T>)
    case disposed
}

enum SteppingCoreError: ErrorProtocol {
    case alreadyHasUnresolvedContinuation
}

/// A stepping can have a scheduled continuation with or without a result.
/// If a continuation is scheduled when there's no result, it'll be stored and executed
/// then the result set.
/// If a continuation is scheduled after a result has been set, it'll be executed immediately.
/// In either case, continuation function will be removed after execution.
/// And once stepped stepping cannot be stepped again.
/// Then, you cannot complete a stepping that is `disposed`.
final class SteppingCore<T> {
    typealias Continuation = ((T) -> ())
    private(set) var state = SteppingState<T>.unscheduledAndUnresolved
    private let lock = Lock()

    init(state: SteppingState<T>) {
        self.state = state
    }
    deinit {
        switch state {
        case .unscheduledAndUnresolved:
            // Bad. Must be resolved.
            fatalError()
        case .unscheduledButResolved(_):
            // Fine. Terminal continuation.
            break
        case .unresolvedButScheduled(_):
            // Bad. Must be resolved.
            fatalError()
        case .disposed:
            // Fine.
            break
        }
    }
    func complete(result: T) {
        lock.lock()
        switch state {
        case .unscheduledAndUnresolved:
            state = .unscheduledButResolved(result)
            lock.unlock()
        case .unscheduledButResolved(_):
            SteppingErrorRepoting.fatalError(.cannotResolveOnceCompletedSteppingAgain(self))
        case .unresolvedButScheduled(let c):
            state = .disposed
            lock.unlock()
            c(result)
        case .disposed:
            SteppingErrorRepoting.fatalError(.cannotCompleteDisposedStepping(self))
        }
    }
    /// Calling this method itself may fail, but continuation process itself must always succeeds.
    /// There's no concept of error or cancellation in continuation.
    func scheduleStepping<U>(into queue: SteppingExecutor, process: (T) -> SteppingCore<U>) throws -> SteppingCore<U> {
        func makeFuturePair() -> (continuation: SteppingContinuation<T>, stepping: SteppingCore<U>) {
            let n2 = SteppingCore<U>(state: .unscheduledAndUnresolved)
            // Take care that this continuation holds both of prior and next
            // stepping objects. A stepping must be disposed to kill them.
            let c = { [n2] (r: T) -> () in
                queue.execute {
                    let n1 = process(r)
                    n1.lock.lock()
                    // You can continue from only unscheduled stepping.
                    switch n1.state {
                    case .unscheduledAndUnresolved:
                        let c2 = { n2.complete(result: $0) }
                        n1.state = .unresolvedButScheduled(c2)
                        n1.lock.unlock()
                    case .unscheduledButResolved(let r):
                        n1.state = .disposed
                        n1.lock.unlock()
                        n2.complete(result: r)
                    case .unresolvedButScheduled(_):
                        fatalError("You cannot continue from a scheduled stepping.")
                    case .disposed:
                        fatalError("You cannot continue from a disposed stepping.")
                    }
//                    n2.complete(result: process(r))
                }
            }
            return (c, n2)
        }

        lock.lock()
        switch state {
        case .unscheduledAndUnresolved:
            let (c, n) = makeFuturePair()
            state = .unresolvedButScheduled(c)
            lock.unlock()
            return n
        case .unresolvedButScheduled(_):
            SteppingErrorRepoting.fatalError(SteppingFatalError.cannotScheduleAlreadyScheduledStepping(self))
        case .unscheduledButResolved(let r):
            let (c, n) = makeFuturePair()
            state = .disposed
            lock.unlock()
            c(r)
            return n
        case .disposed:
            SteppingErrorRepoting.fatalError(SteppingFatalError.cannotScheduleAlreadyDisposedStepping(self))
        }
    }
}

import Foundation
private typealias Lock = Foundation.Lock




























