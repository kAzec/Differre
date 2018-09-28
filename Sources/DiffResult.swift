//
//  DiffResult.swift
//  Differre
//
//  Created by Fengwei Liu on 2018/05/01.
//  Copyright © 2018 kAzec. All rights reserved.
//

public struct DiffResult<Index, Element> where Index : Hashable & Comparable, Element : Hashable {
    /// Insertions at new indices with new elements.
    public let insertions: [(Index, Element)]
    
    /// Deletions at old indices.
    public let deletions: [Index]
    
    /// Updates at new indices with new elements.
    public let updates: [(Index, Element)]
    
    /// Moves from old indices to new indices.
    public let moves: [(Index, Index)]
    
    @inlinable
    public init(
        insertions: [(Index, Element)] = [],
        deletions: [Index] = [],
        updates: [(Index, Element)] = [],
        moves: [(Index, Index)] = []
    ) {
        self.insertions = insertions
        self.deletions = deletions
        self.updates = updates
        self.moves = moves
    }
    
    @inlinable
    public init(_ builder: Builder) {
        self.init(
            insertions: builder.insertions,
            deletions:  builder.deletions,
            updates:    builder.updates,
            moves:      builder.moves
        )
    }
    
    public init<C>(context: DiffContext<C>) where C.Index == Index, C.Element == Element {
        var builder = Builder()
        builder.applyDiff(with: context)
        self.init(builder)
    }
}

public extension DiffResult {
    struct Builder : DiffChangesApplier {
        @usableFromInline
        var insertions = [(Index, Element)]()
        @usableFromInline
        var deletions = [Index]()
        @usableFromInline
        var updates = [(Index, Element)]()
        @usableFromInline
        var moves = [(Index, Index)]()
        
        public mutating func applyInsertion(_ element: Element, at index: Index) {
            insertions.append((index, element))
        }
        
        public mutating func applyDeletion(at index: Index) {
            deletions.append(index)
        }
        
        public mutating func applyUpdateOrMove(
            _ oldElement: Element,
            at oldIndex: Index,
            to newElement: Element,
            at newIndex: Index,
            updated: Bool,
            moved: Bool
        ) {
            switch (updated, moved) {
            case (true, true):
                deletions.append(oldIndex)
                insertions.append((newIndex, newElement))
            case (false, true):
                moves.append((oldIndex, newIndex))
            case (true, false):
                updates.append((newIndex, newElement))
            default: break
            }
        }
    }
}

extension DiffResult : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return """
        <DiffResult>{ \(insertions.count) insertion(s), \(deletions.count) deletion(s), \(updates.count) update(s), \
        \(moves.count) move(s) }
        """
    }
    
    public var debugDescription: String {
        let insertions = AnyCollection(self.insertions.lazy.map { "+\($0.1)@\($0.0)" })
        let deletions = AnyCollection(self.deletions.lazy.map { "-@\($0)" })
        let updates = AnyCollection(self.updates.lazy.map { "!\($0.1)@\($0.0)" })
        let moves = AnyCollection(self.moves.lazy.map { "@\($0.0)>@\($0.1)" })
        
        let changes = [insertions, deletions, updates, moves].joined()
        return "<DiffResult>{ \(changes.joined(separator: ", ")) }"
    }
}
