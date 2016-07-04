//
//  SteppingTests.swift
//  SteppingTests
//
//  Created by Hoon H. on 2016/07/04.
//  Copyright © 2016 Eonil. All rights reserved.
//

import XCTest
@testable import Step

class SteppingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test1() {
        var v1 = 0
        let _ = try! Stepping(111).step{ $0 * 2 }.step{ $0 + 3 }.step{ v1 = $0 }
        XCTAssert(v1 == (111 * 2) + 3)
    }
    func test2() {
        try! Stepping(111).stepTolerantly(on: .immediate) { (v: Int) throws -> String in
            if v == 111 { throw "FAIL" }
            return "999"
        }.cleanse(on: .immediate) { XCTAssert($0 as? String == "FAIL") }
//        XCTAssert(v1 == (111 * 2) + 3)
    }
    func test3() {
        let sc = SteppingController<Int>()
        var s = sc.step
        let N = 1024 * 128
        var tids = Set<mach_port_t>()
        let q = DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosDefault)
        let exp = expectation(withDescription: "test3exp")
        for _ in 0..<N {
            do {
                s = try s.step(on: .specific(q), process: { v in
                    tids.insert(pthread_mach_thread_np(pthread_self()));
                    return v + 1
                })
            }
            catch let e {
                XCTAssert(false, "\(e)")
            }
        }
        var done = false
        let _ = try! s.step(on: .specific(DispatchQueue.main)) {
            XCTAssert($0 == N)
            done = true
            exp.fulfill()
        }
        sc.complete(result: 0)
        waitForExpectations(withTimeout: 20) { (e: NSError?) in
            XCTAssert(e == nil, "\(e)")
        }
        print(tids)
        XCTAssert(tids.count > 1)
        XCTAssert(done == true)
    }
}

extension String: ErrorProtocol {

}








