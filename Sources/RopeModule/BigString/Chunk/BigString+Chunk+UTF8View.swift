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
  struct UTF8View {
    var _base: BigString._Chunk

    init(_ base: BigString._Chunk) {
      self._base = base
    }
  }

  var utf8: UTF8View {
    UTF8View(self)
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.UTF8View: RandomAccessCollection & BidirectionalCollection {
  typealias Index = BigString._Chunk.Index
  
  var startIndex: Index {
    Index(utf8Offset: 0)
  }

  var endIndex: Index {
    Index(utf8Offset: _base.span.count)
  }

  var count: Int {
    _base.span.count
  }

  func index(after i: Index) -> Index {
    Index(utf8Offset: i.utf8Offset + 1)
  }

  func index(before i: Index) -> Index {
    Index(utf8Offset: i.utf8Offset - 1)
  }

  subscript(position: Index) -> UInt8 {
    precondition(position >= startIndex && position < endIndex, "Index out of bounds")
    return _base.span[Int(position.utf8Offset)]
  }
}

#endif
