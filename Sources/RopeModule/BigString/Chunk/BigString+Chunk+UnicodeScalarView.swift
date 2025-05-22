//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if swift(>=5.8)

@available(macOS 9999, *)
extension BigString._Chunk {
  struct UnicodeScalarView {
    var _base: BigString._Chunk

    init(_ base: BigString._Chunk) {
      self._base = base
    }
  }

  var unicodeScalars: UnicodeScalarView {
    UnicodeScalarView(self)
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.UnicodeScalarView: Sequence {
  typealias Element = Unicode.Scalar

  struct Iterator {
    var _base: BigString._Chunk
    var offset = 0
  }

  func makeIterator() -> Iterator {
    Iterator(_base: self._base)
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.UnicodeScalarView.Iterator: IteratorProtocol {
  typealias Element = Unicode.Scalar

  mutating func next() -> Unicode.Scalar? {
    var iter = _base.utf8Span(from: offset).makeUnicodeScalarIterator()
    
    guard let s = iter.next() else {
      return nil
    }
    
    offset &+= s.utf8.count
    
    return s
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.UnicodeScalarView: BidirectionalCollection {
  typealias Index = BigString._Chunk.Index
  
  var startIndex: Index {
    Index(utf8Offset: 0).knownScalarAligned()
  }

  var endIndex: Index {
    Index(utf8Offset: _base.span.count).knownScalarAligned()
  }

  var count: Int {
    Int(_base.counts.unicodeScalars)
  }

  func index(after i: Index) -> Index {
    let i = index(roundingDown: i)
    var si = _base.utf8Span(from: i.utf8Offset).makeUnicodeScalarIterator()
    _ = si.skipForward()
    return Index(utf8Offset: si.currentCodeUnitOffset).knownScalarAligned()
  }

  func index(before i: Index) -> Index {
    let i = index(roundingDown: i)
    var si = _base.utf8Span.makeUnicodeScalarIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipBack()
    return Index(utf8Offset: si.currentCodeUnitOffset).knownScalarAligned()
  }

  subscript(index: Index) -> Unicode.Scalar {
    precondition(index >= startIndex && index < endIndex, "Index out of bounds")
    
    var iter = _base.utf8Span(from: index.utf8Offset).makeUnicodeScalarIterator()
    return iter.next().unsafelyUnwrapped
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.UnicodeScalarView {
  func index(roundingDown i: Index) -> Index {
    if i.isKnownScalarAligned || i.utf8Offset == 0 {
      return i.knownScalarAligned()
    }
    
    if i >= endIndex {
      return endIndex
    }
    
    var si = _base.utf8Span.makeUnicodeScalarIterator()
    si.reset(roundingBackwardsFrom: i.utf8Offset)
    return Index(utf8Offset: si.currentCodeUnitOffset).knownScalarAligned()
  }
}

#endif
