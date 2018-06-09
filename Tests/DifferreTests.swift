//
//  DifferreTests.swift
//  DifferreTests
//
//  Created by Fengwei Liu on 2018/05/01.
//  Copyright © 2018 kAzec. All rights reserved.
//

import XCTest
@testable import Differre

class DifferreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        var os = "åƒåß©©©åßasfa"
        let ns = "😉ååß©åßas🤩🤩fa"
        
        OrderedDiffResult(context: DiffContext(from: os, to: ns)).apply(to: &os)
        
        XCTAssert(os == ns)
    }
}
