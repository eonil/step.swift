//
//  TolerantSteppingCore.swift
//  Step
//
//  Created by Hoon H. on 2016/07/04.
//  Copyright © 2016 Eonil. All rights reserved.
//

final class TolerantSteppingCore<T> {
    private let core: SteppingCore<TolerantSteppingResult<T>>

    private init(core: SteppingCore<TolerantSteppingResult<T>>) {
        self.core = core
    }
    init(state: SteppingState<TolerantSteppingResult<T>>) {
        self.core = SteppingCore<TolerantSteppingResult<T>>(state: state)
    }
    func complete(result: TolerantSteppingResult<T>) {
        core.complete(result: result)
    }
    /// Continuation can recover from prior error.
    @warn_unused_result
    func scheduleContinuation<U>(into executor: SteppingExecutor, process: (TolerantSteppingResult<T>) throws -> TolerantSteppingResult<U>) throws -> TolerantSteppingCore<U> {
        let n = try core.scheduleStepping(into: executor) { (r: TolerantSteppingResult<T>) -> TolerantSteppingResult<U> in
            do {
                return try process(r)
            }
            catch let e {
                return .error(e)
            }
        }
        return TolerantSteppingCore<U>(core: n)
    }
}
