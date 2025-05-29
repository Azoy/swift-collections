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
  func utf16AlignIndex(_ i: Index) -> Index {
    var i = i
    
    if !i.isUTF16TrailingSurrogate {
      i = unicodeScalars.index(roundingDown: i)
    }
    
    return i
  }
  
  func utf16Index(after i: Index) -> Index {
    let i = utf16AlignIndex(i)
    let len = unicodeScalars[i].utf8.count
    
    // Check for non-BMP scalars and mark the index as a trailing surrogate if
    // needed.
    if len == 4, !i.isUTF16TrailingSurrogate {
      return i.nextUTF16Trailing
    }
    
    return i.offset(by: len).scalarAligned
  }
  
  func utf16Index(before i: Index) -> Index {
    // If we have a trailing surrogate, then we just strip the bit to indicate
    // we're looking at the leading surrogate.
    if i.isUTF16TrailingSurrogate {
      return i.stripUTF16Trailing.scalarAligned
    }
    
    let i = utf16AlignIndex(i)
    var len = 1
    
    while UTF8.isContinuation(self[utf8: i.offset(by: -len)]) {
      len += 1
    }
    
    if len == 4 {
      return i.offset(by: -len).nextUTF16Trailing
    }
    
    return i.offset(by: -len).scalarAligned
  }
  
  func utf16Distance(from i: Index, to j: Index) -> Int {
    guard i != j else {
      return 0
    }
    
    precondition((startIndex ..< endIndex).contains(i), "Index out of bounds")
    precondition((startIndex ..< endIndex).contains(j), "Index out of bounds")
    
    let utf8Offset = j.utf8Offset - i.utf8Offset
    
    
    
    return 0
  }
  
  subscript(utf16 i: Index) -> UInt16 {
    precondition((startIndex ..< endIndex).contains(i), "Index out of bounds")
    
    let s = unicodeScalars[i]
    
    if i.isUTF16TrailingSurrogate {
      return s.utf16[1]
    } else {
      return s.utf16[0]
    }
  }
}

#endif
