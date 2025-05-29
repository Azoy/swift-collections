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
extension BigString._Chunk.UnicodeScalarView: BidirectionalCollection {
  typealias Index = BigString._Chunk.Index
  
  var startIndex: Index {
    _base.startIndex
  }

  var endIndex: Index {
    _base.endIndex
  }

  var count: Int {
    Int(_base.counts.unicodeScalars)
  }

  func index(after i: Index) -> Index {
    let i = index(roundingDown: i)
    var si = _base.utf8Span.makeUnicodeScalarIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipForward()
    return Index(utf8Offset: si.currentCodeUnitOffset).scalarAligned
  }

  func index(before i: Index) -> Index {
    let i = index(roundingDown: i)
    var si = _base.utf8Span.makeUnicodeScalarIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipBack()
    return Index(utf8Offset: si.currentCodeUnitOffset).scalarAligned
  }

  subscript(index: Index) -> Unicode.Scalar {
    precondition(index >= startIndex && index < endIndex, "Index out of bounds")
    
    var iter = _base.utf8Span.makeUnicodeScalarIterator()
    iter.reset(toUnchecked: index.utf8Offset)
    return iter.next().unsafelyUnwrapped
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.UnicodeScalarView {
  func index(roundingDown i: Index) -> Index {
    if i.isKnownScalarAligned || i.utf8Offset == 0 {
      return i.scalarAligned
    }
    
    if i == endIndex {
      return endIndex
    }
    
    var si = _base.utf8Span.makeUnicodeScalarIterator()
    si.reset(roundingBackwardsFrom: i.utf8Offset)
    return Index(utf8Offset: si.currentCodeUnitOffset).scalarAligned
  }
}

#endif
