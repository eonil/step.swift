//
//  SteppingExecutor.swift
//  Step
//
//  Created by Hoon H. on 2016/07/04.
//  Copyright © 2016 Eonil. All rights reserved.
//

import Dispatch

public enum SteppingExecutor {
    /// Executes continuation on result setter's current queue synchronously.
    case immediate
    case specific(DispatchQueue)
}
