//
//  DiffContext.swift
//  Differre
//
//  Created by Fengwei Liu on 2018/05/01.
//  Copyright © 2018 kAzec. All rights reserved.
//

/// DiffContext is the initial setup of the OA and NA arrays. It is than processed to create the diff steps.
/// By the end of `setupContext`, the context is the state showed at the figure 1 of the Paul Heckel's paper.
public struct DiffContext<C : Collection> where C.Element : Hashable {
    /// Paul Heckel's paper O array.
    public private(set) var O: C
    
    /// Paul Heckel's paper N array.
    public private(set) var N: C
    
    /// Paul Heckel's paper OA array.
    public private(set) var OA = ContiguousArray<DiffReference>()
    
    /// Paul Heckel's paper NA array.
    public private(set) var NA = ContiguousArray<DiffReference>()
    
    /// Paul Heckels's paper table.
    public private(set) var table = [Int : DiffReference.Symbol]()
    
    /**
     Creates and setups the context.
     Complexity: **O(n+m)** where `n` is `source.count` and `m` is `destination.count`.
     - parameter source: The array to calculate from.
     - parameter destination: The array to calculate to.
     */
    @_inlineable
    public init(from source: C, to destination: C) {
        self.O = source
        self.N = destination
        
        calculate()
    }
    
    @_inlineable
    public mutating func update(with newDestination: C) {
        O = N
        N = newDestination
        
        OA.removeAll()
        NA.removeAll()
        table.removeAll()
        
        calculate()
    }
    
    @_versioned
    mutating func calculate() {
        // First pass
        for element in N {
            let hashValue = element.hashValue
            let symbol: DiffReference.Symbol
            
            if let existingSymbol = table[hashValue] {
                symbol = existingSymbol
                symbol.NC.advance()
            } else {
                symbol = DiffReference.Symbol(OC: .zero, NC: .one)
                table[hashValue] = symbol
            }
            
            NA.append(.symbol(symbol))
        }
        
        // Second pass
        for (i, element) in O.enumerated() {
            let hashValue = element.hashValue
            let symbol: DiffReference.Symbol
            
            if let existingSymbol = table[hashValue] {
                symbol = existingSymbol
                symbol.OC.advance(with: i)
            } else {
                symbol = DiffReference.Symbol(OC: .one(OLNO: i), NC: .zero)
                table[hashValue] = symbol
            }
            
            OA.append(.symbol(symbol))
        }
        
        // Third pass
        for case (let index, .symbol(let symbol)) in NA.enumerated() {
            if case .one = symbol.NC, case .one(let OLNO) = symbol.OC {
                NA[index] = .index(OLNO)
                OA[OLNO] = .index(index)
            }
        }
        
        // Fourth pass
        var i = 0
        while i < NA.count - 1 {
            if
                case .index(let j) = NA[i],
                j + 1 < OA.count,
                case .symbol(let new) = NA[i + 1],
                case .symbol(let old) = OA[j + 1],
                new === old
            {
                NA[i + 1] = .index(j + 1)
                OA[j + 1] = .index(i + 1)
            }
            
            i += 1
        }
        
        // Fifth pass
        i = NA.count - 1
        while i > 0 {
            if
                case .index(let j) = NA[i],
                j - 1 >= 0,
                case .symbol(let new) = NA[i - 1],
                case .symbol(let old) = OA[j - 1],
                new === old
            {
                NA[i - 1] = .index(j - 1)
                OA[j - 1] = .index(i - 1)
            }
            
            i -= 1
        }
    }
}

public enum DiffReference {
    public final class Symbol {
        public enum NewCounter {
            case zero
            case one
            case many
            
            @inline(__always)
            public mutating func advance() {
                if case .zero = self {
                    self = .one
                } else {
                    self = .many
                }
            }
        }
        
        public enum OldCounter {
            case zero
            case one(OLNO: Int)
            case many
            
            @inline(__always)
            public mutating func advance(with OLNO: Int) {
                if case .zero = self {
                    self = .one(OLNO: OLNO)
                } else {
                    self = .many
                }
            }
        }
        
        public var OC: OldCounter
        public var NC: NewCounter
        
        init(OC: OldCounter, NC: NewCounter) {
            self.OC = OC
            self.NC = NC
        }
    }
    
    case symbol(Symbol)
    case index(Int)
}
