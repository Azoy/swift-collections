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
  func characterIndex(
    roundingDown i: Index,
    in range: Range<Index>? = nil
  ) -> Index {
    precondition(hasBreaks, "Chunk must have a break to round")
    
    if i.isKnownCharacterAligned || i.utf8Offset == 0 {
      return i.characterAligned
    }
    
    if i == endIndex {
      return endIndex
    }
    
    let range = range ?? firstBreak ..< endIndex
    let span = utf8Span(from: range.lowerBound, to: range.upperBound)
    
    var iter = span.makeCharacterIterator()
    iter.reset(toUnchecked: i.utf8Offset - range.lowerBound.utf8Offset)
    _ = iter.skipBack()
    let start = iter.currentCodeUnitOffset
    _ = iter.skipForward()
    
    if iter.currentCodeUnitOffset == i.utf8Offset - range.lowerBound.utf8Offset {
      return i.characterAligned
    }
    
    return Index(utf8Offset: start + range.lowerBound.utf8Offset).characterAligned
  }
  
  func characterIndex(after i: Index) -> Index {
    let i = characterIndex(roundingDown: i)
    var si = utf8Span.makeCharacterIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipForward()
    return Index(utf8Offset: si.currentCodeUnitOffset).characterAligned
  }
  
  func characterIndex(before i: Index, in range: Range<Index>? = nil) -> Index {
    let range = range ?? firstBreak..<i
    
    let i = characterIndex(roundingDown: i, in: range)
    var si = utf8Span(from: range.lowerBound, to: range.upperBound).makeCharacterIterator()
    si.reset(toUnchecked: i.utf8Offset - range.lowerBound.utf8Offset)
    _ = si.skipBack()
    return Index(utf8Offset: si.currentCodeUnitOffset + range.lowerBound.utf8Offset).characterAligned
  }
  
  func characterIndex(_ i: Index, offsetBy n: Int) -> Index {
    var i = characterIndex(roundingDown: i)
    
    if n >= 0 {
      for _ in stride(from: 0, to: n, by: 1) {
        i = characterIndex(after: i)
      }
    } else {
      for _ in stride(from: 0, to: n, by: -1) {
        i = characterIndex(before: i)
      }
    }
    
    return i
  }
  
  func characterIndex(
    _ i: Index,
    offsetBy n: Int,
    limitedBy limit: Index
  ) -> Index? {
    guard limit <= endIndex else {
      return characterIndex(i, offsetBy: n)
    }
    
    precondition((firstBreak...lastBreak).contains(i), "Index out of bounds")
    
    var i = characterIndex(roundingDown: i)
    let limit = characterIndex(roundingDown: limit)
    
    if n >= 0 {
      for _ in stride(from: 0, to: n, by: 1) {
        if i == limit {
          return nil
        }
        
        i = characterIndex(after: i)
      }
    } else {
      for _ in stride(from: 0, to: n, by: -1) {
        if i == limit {
          return nil
        }
        
        i = characterIndex(before: i)
      }
    }
    
    return i
  }
  
  func characterDistance(from start: Index, to end: Index) -> Int {
    precondition((firstBreak...lastBreak).contains(start), "Index out of bounds")
    precondition((firstBreak...endIndex).contains(end), "Index out of bounds")
    
    let start = characterIndex(roundingDown: start)
    let end = characterIndex(roundingDown: end)
    
    var i = start
    var count = 0
    
    if i < end {
      while i < end {
        count += 1
        i = characterIndex(after: i)
      }
    } else if i > end {
      while i > end {
        count -= 1
        i = characterIndex(before: i)
      }
    }
    
    return count
  }
  
  subscript(character i: Index) -> Character {
    precondition((firstBreak...lastBreak).contains(i), "Index out of bounds")
    
    var iter = utf8Span.makeCharacterIterator()
    iter.reset(toUnchecked: i.utf8Offset)
    return iter.next().unsafelyUnwrapped
  }
}

@available(macOS 26, *)
extension UInt8 {
  /// Returns true if this is a leading code unit in the UTF-8 encoding of a Unicode scalar that
  /// is outside the BMP.
  var _isUTF8NonBMPLeadingCodeUnit: Bool { self >= 0b11110000 }
}

@available(macOS 26, *)
extension BigString._Chunk {
  /// If this returns false, the next position is on the first grapheme break following this
  /// chunk.
  func formCharacterIndex(after i: inout BigString._Chunk.Index) -> Bool {
    if i >= lastBreak {
      i = endIndex
      return false
    }
    let first = firstBreak
    if i < first {
      i = first
      return true
    }
    
    i = characterIndex(after: i)
    return true
  }

  /// If this returns false, the right position is `distance` steps from the first grapheme break
  /// following this chunk if `distance` was originally positive. Otherwise the right position is
  /// `-distance` steps from the first grapheme break preceding this chunk.
  func formCharacterIndex(
    _ i: inout Index,
    offsetBy distance: inout Int
  ) -> (found: Bool, forward: Bool) {
    if distance == 0 {
      if i < firstBreak {
        i = startIndex
        return (false, false)
      }
      if i >= lastBreak {
        i = lastBreak
        return (true, false)
      }
      i = characterIndex(roundingDown: i)
      return (true, false)
    }
    if distance > 0 {
      if i >= lastBreak {
        i = endIndex
        distance -= 1
        return (false, true)
      }
      if i < firstBreak {
        i = firstBreak
        distance -= 1
        if distance == 0 { return (true, true) }
      }
      if
        distance <= characterCount,
        let r = characterIndex(i, offsetBy: distance, limitedBy: endIndex)
      {
        i = r
        distance = 0
        return (i < endIndex, true)
      }
      distance -= characterDistance(from: i, to: lastBreak) + 1
      i = endIndex
      return (false, true)
    }
    if i <= firstBreak {
      i = startIndex
      if i == firstBreak { distance += 1 }
      return (false, false)
    }
    if i > lastBreak {
      i = lastBreak
      distance += 1
      if distance == 0 { return (true, false) }
    }
    if
      distance.magnitude <= characterCount,
      let r = characterIndex(i, offsetBy: distance, limitedBy: firstBreak)
    {
      i = r
      distance = 0
      return (true, false)
    }
    distance += characterDistance(from: firstBreak, to: i)
    i = startIndex
    return (false, false)
  }
}

#endif
