//
//  OrderedDiffResult.swift
//  Differre
//
//  Created by Fengwei Liu on 2018/05/01.
//  Copyright © 2018 kAzec. All rights reserved.
//

public struct OrderedDiffResult<Index, Element> where Index : Comparable, Element : Hashable {
    public enum Step {
        case insert(Element, at: Index)
        case delete(at: Index)
        case update(Element, at: Index)
        
        @_inlineable
        public var description: String {
            switch self {
            case .insert(let element, at: let index): return "+\(element)@\(index)"
            case .delete(at: let index):              return "-@\(index)"
            case .update(let element, at: let index): return "!\(element)@\(index)"
            }
        }
    }
    
    public var steps: ContiguousArray<Step>
    
    @_inlineable
    public init(steps: ContiguousArray<Step> = []) {
        self.steps = steps
    }
    
    @_inlineable
    public init<Steps : Sequence>(steps: Steps) where Steps.Element == Step {
        self.steps = ContiguousArray(steps)
    }
    
    @_inlineable
    public init(_ builder: Builder) {
        var deletions = ContiguousArray<Step>()
        deletions.reserveCapacity(builder.deletionIndices.count)

        for deletionIndex in builder.deletionIndices.sorted(by: >) {
            deletions.append(.delete(at: deletionIndex))
        }

        self.steps = deletions + builder.insertions + builder.updates
    }
    
    public init<C>(context: DiffContext<C>) where C.Index == Index, C.Element == Element {
        var builder = Builder()
        builder.applyDiff(with: context)
        self.init(builder)
    }
}

public extension OrderedDiffResult {
    struct Builder : DiffChangesApplier {
        @_versioned
        var updates = ContiguousArray<OrderedDiffResult<Index, Element>.Step>()
        @_versioned
        var insertions = ContiguousArray<OrderedDiffResult<Index, Element>.Step>()
        @_versioned
        var deletionIndices = ContiguousArray<Index>()
        
        @_inlineable
        public mutating func applyInsertion(_ element: Element, at index: Index) {
            insertions.append(.insert(element, at: index))
        }
        
        @_inlineable
        public mutating func applyDeletion(at index: Index) {
            deletionIndices.append(index)
        }
        
        @_inlineable
        public mutating func applyUpdateOrMove(
            _ oldElement: Element,
            at oldIndex: Index,
            to newElement: Element,
            at newIndex: Index,
            updated: Bool,
            moved: Bool
        ) {
            if moved {
                insertions.append(.insert(newElement, at: newIndex))
                deletionIndices.append(oldIndex)
            } else if updated {
                updates.append(.update(newElement, at: newIndex))
            }
        }
    }
}

extension OrderedDiffResult {
    @_inlineable
    public func apply<Subject : RangeReplaceableCollection & MutableCollection>(
        to subject: inout Subject
    ) where Subject.Index == Index, Subject.Element == Element {
        for step in steps {
            switch step {
            case .insert(let element, at: let index):
                subject.insert(element, at: index)
            case .delete(at: let index):
                subject.remove(at: index)
            case .update(let element, at: let index):
                subject[index] = element
            }
        }
    }
    
    @_inlineable
    public func apply<Subject : RangeReplaceableCollection>(
        to subject: inout Subject
    ) where Subject.Index == Index, Subject.Element == Element {
        for step in steps {
            switch step {
            case .insert(let element, at: let index):
                subject.insert(element, at: index)
            case .delete(at: let index):
                subject.remove(at: index)
            case .update(let element, at: let index):
                subject.replaceSubrange(index...index, with: CollectionOfOne(element))
            }
        }
    }
}

extension OrderedDiffResult : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "<OrderedDiffResult>{ \(steps.count) step(s) }"
    }
    
    public var debugDescription: String {
        return "<OrderedDiffResult>{ \(steps.lazy.map { String(describing: $0) }.joined(separator: ", ")) }"
    }
}
