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

@available(macOS 26, *)
extension BigString._Chunk {
  func utf8ScalarLength(_ byte: UInt8) -> Int {
    if UTF8.isASCII(byte) {
      return 1
    }
    
    return (~byte).leadingZeroBitCount
  }
  
  func scalarIndex(roundingDown i: Index) -> Index {
    if i.isKnownScalarAligned || i.utf8Offset == 0 {
      return i.scalarAligned
    }
    
    if i == endIndex {
      return endIndex
    }
    
    var si = utf8Span.makeUnicodeScalarIterator()
    si.reset(roundingBackwardsFrom: i.utf8Offset)
    return Index(utf8Offset: si.currentCodeUnitOffset).scalarAligned
  }
  
  func scalarIndex(after i: Index) -> Index {
    let i = scalarIndex(roundingDown: i)
    var si = utf8Span.makeUnicodeScalarIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipForward()
    return Index(utf8Offset: si.currentCodeUnitOffset).scalarAligned
  }
  
  func scalarIndex(before i: Index) -> Index {
    let i = scalarIndex(roundingDown: i)
    var si = utf8Span.makeUnicodeScalarIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipBack()
    return Index(utf8Offset: si.currentCodeUnitOffset).scalarAligned
  }
  
  func scalarIndex(_ i: Index, offsetBy n: Int) -> Index {
    var i = scalarIndex(roundingDown: i)
    
    if n >= 0 {
      for _ in stride(from: 0, to: n, by: 1) {
        i = scalarIndex(after: i)
      }
    } else {
      for _ in stride(from: 0, to: n, by: -1) {
        i = scalarIndex(before: i)
      }
    }
    
    return i
  }
  
  func scalarDistance(from start: Index, to end: Index) -> Int {
    let start = scalarIndex(roundingDown: start)
    let end = scalarIndex(roundingDown: end)
    
    var i = start
    var count = 0
    
    if i < end {
      while i < end {
        count += 1
        i = scalarIndex(after: i)
      }
    } else if i > end {
      while i > end {
        count -= 1
        i = scalarIndex(before: i)
      }
    }
    
    return count
  }
  
  subscript(scalar i: Index) -> Unicode.Scalar {
    precondition((startIndex..<endIndex).contains(i), "Index out of bounds")
    
    let i = scalarIndex(roundingDown: i)
    
    var iter = utf8Span.makeUnicodeScalarIterator()
    iter.reset(toUnchecked: i.utf8Offset)
    return iter.next().unsafelyUnwrapped
  }
}

#endif
