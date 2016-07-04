//
//  Stepping.swift
//  Step
//
//  Created by Hoon H. on 2016/07/04.
//  Copyright © 2016 Eonil. All rights reserved.
//

/// Provide coroutine like abstraction using Promise mechanics.
public struct Stepping<T> {
    private let core: SteppingCore<T>
    private init(core: SteppingCore<T>) {
        self.core = core
    }
    public init(_ result: T) {
        self.core = SteppingCore(state: .unscheduledButResolved(result))
    }
    public func step<U>(process: (T) -> U) throws -> Stepping<U> {
        return try step(on: .immediate, process: process)
    }
    /// Continues on success.
    /// Skips to next on any error.
    public func step<U>(on executor: SteppingExecutor, process: (T) -> U) throws -> Stepping<U> {
        let c = try core.scheduleStepping(into: executor) { (result: T) -> U in
            return process(result)
        }
        return Stepping<U>(core: c)
    }
}

public struct SteppingController<T> {
    let step = Stepping<T>(core: SteppingCore<T>(state: .unscheduledAndUnresolved))
    func complete(result: T) {
        step.core.complete(result: result)
    }
}
