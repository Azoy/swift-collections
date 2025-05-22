////===----------------------------------------------------------------------===//
////
//// This source file is part of the Swift Collections open source project
////
//// Copyright (c) 2025 Apple Inc. and the Swift project authors
//// Licensed under Apache License v2.0 with Runtime Library Exception
////
//// See https://swift.org/LICENSE.txt for license information
////
////===----------------------------------------------------------------------===//
//
//#if swift(>=5.8)
//
//@available(macOS 9999, *)
//extension BigString._Chunk {
//  struct UTF16View {
//    var _base: BigString._Chunk
//
//    init(_ base: BigString._Chunk) {
//      self._base = base
//    }
//  }
//
//  var utf16: UTF16View {
//    UTF16View(self)
//  }
//}
//
//@available(macOS 9999, *)
//extension BigString._Chunk.UTF16View: BidirectionalCollection {
//  typealias Index = BigString._Chunk.Index
//  
//  var startIndex: Index {
//    Index(utf8Offset: 0)
//  }
//
//  var endIndex: Index {
//    Index(utf8Offset: _base.bytes.count)
//  }
//
//  var count: Int {
//    Int(_base.counts.utf16)
//  }
//
//  func index(after i: Index) -> Index {
//    guard i < endIndex else {
//      return endIndex
//    }
//    
//    var si = _base.utf8Span(from: i.utf8Offset).
//    _ = si.skipForward()
//    return Index(utf8Offset: si.currentCodeUnitOffset)
//  }
//
//  func index(before i: Index) -> Index {
//    Index(utf8Offset: i.utf8Offset - 1)
//  }
//
//  subscript(position: Index) -> UInt8 {
//    precondition(position >= startIndex && position < endIndex, "Index out of bounds")
//    return _base.bytes[Int(position.utf8Offset)]
//  }
//}
//
//#endif
