//
//  DiffApplier.swift
//  Hiive
//
//  Created by Fengwei Liu on 2018/06/09.
//  Copyright © 2018 Fengwei Liu. All rights reserved.
//

public protocol DiffApplier {
    associatedtype Index : Comparable
    associatedtype Element : Hashable
    
    mutating func applyDiff<C>(with context: DiffContext<C>) where C.Index == Index, C.Element == Element
}

public protocol DiffChangesApplier : DiffApplier {
    mutating func applyInsertion(_ element: Element, at index: Index)
    mutating func applyDeletion(at index: Index)
    mutating func applyUpdateOrMove(
        _ oldElement: Element,
        at oldIndex: Index,
        to newElement: Element,
        at newIndex: Index,
        updated: Bool,
        moved: Bool
    )
}

public extension DiffChangesApplier {
    @_inlineable
    mutating func applyDiff<C>(with context: DiffContext<C>) where C.Index == Index, C.Element == Element {
        var deleteOffsets = ContiguousArray<Int>()
        deleteOffsets.reserveCapacity(context.OA.count)
        var runningOffset = 0
        
        let oldStartIndex = context.O.startIndex
        let newStartIndex = context.N.startIndex
        
        for (i, reference) in context.OA.enumerated() {
            deleteOffsets.append(runningOffset)
            
            if case .symbol = reference {
                applyDeletion(at: context.O.index(oldStartIndex, offsetBy: i))
                runningOffset += 1
            }
        }
        
        runningOffset = 0
        
        for (i, reference) in context.NA.enumerated() {
            switch reference {
            case .symbol:
                let index = context.N.index(newStartIndex, offsetBy: i)
                applyInsertion(context.N[index], at: index)
                runningOffset += 1
            case .index(let j):
                let oldIndex = context.O.index(oldStartIndex, offsetBy: j)
                let newIndex = context.N.index(newStartIndex, offsetBy: i)
                let oldElement = context.O[oldIndex]
                let newElement = context.N[newIndex]
                
                // The object is not at the expected position, so move it.
                if (j - deleteOffsets[j] + runningOffset) != i {
                    applyUpdateOrMove(
                        oldElement,
                        at:      oldIndex,
                        to:      newElement,
                        at:      newIndex,
                        updated: oldElement != newElement,
                        moved:   true
                    )
                } else if oldElement != newElement {
                    // The object has changed, so it should be updated.
                    applyUpdateOrMove(
                        oldElement,
                        at:      oldIndex,
                        to:      newElement,
                        at:      newIndex,
                        updated: true,
                        moved:   false
                    )
                }
            }
        }
    }
}
