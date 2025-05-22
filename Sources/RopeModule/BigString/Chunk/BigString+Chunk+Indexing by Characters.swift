//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if swift(>=5.8)

@available(macOS 9999, *)
extension UInt8 {
  /// Returns true if this is a leading code unit in the UTF-8 encoding of a Unicode scalar that
  /// is outside the BMP.
  var _isUTF8NonBMPLeadingCodeUnit: Bool { self >= 0b11110000 }
}

@available(macOS 9999, *)
extension BigString._Chunk {
  func characterDistance(
    from start: BigString._Chunk.Index,
    to end: BigString._Chunk.Index
  ) -> Int {
    let firstBreak = self.firstBreak
    let (start, a) = start < firstBreak ? (firstBreak, 1) : (start, 0)
    let (end, b) = end < firstBreak ? (firstBreak, 1) : (end, 0)
    let d = characters.distance(from: start, to: end)
    return d + a - b
  }

  /// If this returns false, the next position is on the first grapheme break following this
  /// chunk.
  func formCharacterIndex(after i: inout BigString._Chunk.Index) -> Bool {
    if i >= lastBreak {
      i = utf8.endIndex
      return false
    }
    let first = firstBreak
    if i < first {
      i = first
      return true
    }
    characters.formIndex(after: &i)
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
        i = characters.startIndex
        return (false, false)
      }
      if i >= lastBreak {
        i = lastBreak
        return (true, false)
      }
      i = characters.index(roundingDown: i)
      return (true, false)
    }
    if distance > 0 {
      if i >= lastBreak {
        i = characters.endIndex
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
        let r = characters.index(i, offsetBy: distance, limitedBy: characters.endIndex)
      {
        i = r
        distance = 0
        return (i < characters.endIndex, true)
      }
      distance -= characters.distance(from: i, to: lastBreak) + 1
      i = characters.endIndex
      return (false, true)
    }
    if i <= firstBreak {
      i = characters.startIndex
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
      let r = characters.index(i, offsetBy: distance, limitedBy: firstBreak)
    {
      i = r
      distance = 0
      return (true, false)
    }
    distance += characters.distance(from: firstBreak, to: i)
    i = characters.startIndex
    return (false, false)
  }
}

#endif
