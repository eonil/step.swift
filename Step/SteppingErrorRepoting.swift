//
//  SteppingErrorRepoting.swift
//  Step
//
//  Created by Hoon H. on 2016/07/05.
//  Copyright © 2016 Eonil. All rights reserved.
//

public enum SteppingFatalError: ErrorProtocol {
    case cannotCompleteDisposedStepping(AnyObject)
    case cannotResolveOnceCompletedSteppingAgain(AnyObject)
    case cannotScheduleAlreadyScheduledStepping(AnyObject)
    case cannotScheduleAlreadyDisposedStepping(AnyObject)
    case cannotDeinitUndisposedTolerantStepping(AnyObject)
}
extension SteppingFatalError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cannotCompleteDisposedStepping(let o):            return "You cannot complete a disposed stepping `\(o)`."
        case .cannotResolveOnceCompletedSteppingAgain(let o):   return "You cannot resolve a completed stepping `\(o)` again."
        case .cannotScheduleAlreadyScheduledStepping(let o):    return "You cannot schedule a continuation to an already scheduled stepping `\(o)`."
        case .cannotScheduleAlreadyDisposedStepping(let o):     return "You cannot schedule a continuation to an already disposed stepping `\(o)`."
        case .cannotDeinitUndisposedTolerantStepping(let o):    return "You MUST properly terminate a tolerant-stepping `\(o)` by continuing to a non-tolerant stepping. Which means you must cleanse any possible errors."
        }
    }
}

/// Stepping reports fatal errors before it crashes.
/// This is provided for testability.
/// Erros will be reported immediately/synchronously
/// from the thread/queue that caused from.
public struct SteppingErrorRepoting {
    public static var fatalErrorHandler: ((SteppingFatalError) -> ())?
    @noreturn
    static func fatalError(_ error: SteppingFatalError) {
        SteppingErrorRepoting.fatalErrorHandler?(error)
        Swift.fatalError("\(error)")
    }
}
