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

struct TableViewSectionUpdater<Element : Hashable> : DiffChangesApplier {
    typealias Index = Int

    let tableView: UITableView
    let sectionIndex: Int
    let rowAnimation: UITableView.RowAnimation
    
    func applyDeletion(at index: Int) {
        tableView.deleteRows(at: [IndexPath(row: index, section: sectionIndex)], with: rowAnimation)
    }
    
    func applyInsertion(_ element: Element, at index: Int) {
        tableView.insertRows(at: [IndexPath(row: index, section: sectionIndex)], with: rowAnimation)
    }
    
    func applyUpdateOrMove(
        _ oldElement: Element,
        at oldIndex: Int,
        to newElement: Element,
        at newIndex: Int,
        updated: Bool,
        moved: Bool
    ) {
        applyDeletion(at: oldIndex)
        applyInsertion(newElement, at: newIndex)
    }
}
