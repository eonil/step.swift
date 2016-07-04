//
//  TolerantStepping.swift
//  Step
//
//  Created by Hoon H. on 2016/07/04.
//  Copyright © 2016 Eonil. All rights reserved.
//

public enum TolerantSteppingResult<T> {
    case done(T)
    case error(ErrorProtocol)
}

/// A stepping which can fail.
public struct TolerantStepping<T> {
    private let core: TolerantSteppingCore<T>
    private init(core: TolerantSteppingCore<T>) {
        self.core = core
    }
    init(_ value: T) {
        self = TolerantStepping(result: .done(value))
    }
    init(result: TolerantSteppingResult<T>) {
        self.core = TolerantSteppingCore(state: .unscheduledButResolved(result))
    }
    @warn_unused_result(message: "You MUST consume returning `TolerantStepping` and recover error at some point. Otherwise, execution will CRASH at the end.")
    func stepTolerantly<U>(process: (T) throws -> U) throws -> TolerantStepping<U> {
        return try stepTolerantly(on: .immediate, process: process)
    }
    /// Continues on success.
    /// Skips to next on any error.
    @warn_unused_result(message: "You MUST consume returning `TolerantStepping` and recover error at some point. Otherwise, execution will CRASH at the end.")
    func stepTolerantly<U>(on executor: SteppingExecutor, process: (T) throws -> U) throws -> TolerantStepping<U> {
        do {
            let c = try core.scheduleContinuation(into: executor) { (result: TolerantSteppingResult<T>) -> TolerantSteppingResult<U> in
                switch result {
                case .done(let v):
                    do {
                        return .done(try process(v))
                    }
                    catch let e {
                        return .error(e)
                    }
                case .error(let e):
                    return .error(e)
                }
            }
            return TolerantStepping<U>(core: c)
        }
        catch let e {
            let c = TolerantSteppingCore<U>(state: .unscheduledButResolved(.error(e)))
            return TolerantStepping<U>(core: c)
        }
    }
}
public protocol TolerantSteppingType {
    associatedtype ResultType
    func stepTolerantly<Derivation>(on executor: SteppingExecutor, process: (ResultType) throws -> Derivation) throws -> TolerantStepping<Derivation>
}
//public extension TolerantSteppingType where Self: TolerantStepping<()>, ResultType == () {
public extension TolerantStepping {
    /// Terminates tolerant stepping in error state.
    /// All processing flow must end cleanly. So you must handle the error
    /// at the end of the flow.
    func cleanse(on executor: SteppingExecutor, process: (ErrorProtocol) -> ()) throws {
        let _ = try core.scheduleContinuation(into: executor) { (result: TolerantSteppingResult<T>) -> TolerantSteppingResult<T> in
            switch result {
            case .done:
                // Abandon result.
                break
            case .error(let e):
                process(e)
            }
            return result
        }
    }
    /// Recovers from any prior error and continues stepping.
    /// This is equivalent with continue after `cleanse(...)`.
    func recover(on executor: SteppingExecutor, process: (ErrorProtocol) -> T) throws -> Stepping<T> {
        let c = SteppingController<T>()
        let _ = try core.scheduleContinuation(into: executor) { (result: TolerantSteppingResult<T>) -> TolerantSteppingResult<T> in
            switch result {
            case .done(let v):
                // Result is always `()`.
                c.complete(result: v)
            case .error(let e):
                c.complete(result: process(e))
            }
            return result
        }
        return c.step
    }
}
public extension Stepping {
    func stepTolerantly<U>(on: SteppingExecutor, process: (T) throws -> U) throws -> TolerantStepping<U> {
        let c = TolerantSteppingController<U>()
        let _ = try step(on: on) { (result: T) -> () in
            do {
                let result1 = try process(result)
                c.complete(result: .done(result1))
                return ()
            }
            catch let e {
                c.complete(result: .error(e))
                return ()
            }
        }
        return c.step
    }
}
public struct TolerantSteppingController<T> {
    let step = TolerantStepping<T>(core: TolerantSteppingCore<T>(state: .unscheduledAndUnresolved))
    func complete(result: TolerantSteppingResult<T>) {
        step.core.complete(result: result)
    }
}

