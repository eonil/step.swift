//
//  SteppingExtensions.swift
//  Step
//
//  Created by Hoon H. on 2016/07/05.
//  Copyright © 2016 Eonil. All rights reserved.
//

import Foundation

//extension Stepping: SteppingType {
//    typealias Result = T
//}
//protocol SteppingType {
//    associatedtype Result
//    func step<Derivation>(on executor: SteppingExecutor, process: (Result) -> Stepping<Derivation>) throws -> Stepping<Derivation>
//}
//extension SteppingType where Result == () {
//
//}
extension Stepping {
    func wait(on queue: DispatchQueue, for duration: DispatchTimeInterval) throws -> Stepping<T> {
        return try step(on: SteppingExecutor.specific(queue)) { result in
            let c = SteppingController<T>()
            queue.after(when: DispatchTime.now() + duration) {
                c.complete(result: result)
            }
            return c.step
        }
    }
}
