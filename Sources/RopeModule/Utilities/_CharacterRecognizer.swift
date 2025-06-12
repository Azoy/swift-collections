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

@available(macOS 26, *)
internal typealias _CharacterRecognizer = Unicode._CharacterRecognizer

@available(macOS 26, *)
extension _CharacterRecognizer {
  internal func _isKnownEqual(to other: Self) -> Bool {
    // FIXME: Enable when Swift 5.9 ships.
//  #if swift(>=5.9)
//    if #available(macOS 26, iOS 9999, tvOS 9999, watchOS 9999, *) { // SwiftStdlib 5.9
//      return self == other
//    }
//  #endif
    return false
  }
}


@available(macOS 26, *)
extension _CharacterRecognizer {
  mutating func firstBreak(
    in str: Substring
  ) -> Range<String.Index>? {
    let r = str.utf8.withContiguousStorageIfAvailable { buffer in
      self._firstBreak(inUncheckedUnsafeUTF8Buffer: buffer)
    }
    if let r {
      guard let scalarRange = r else { return nil }
      let lower = str._utf8Index(at: scalarRange.lowerBound)
      let upper = str._utf8Index(at: scalarRange.upperBound)
      return lower ..< upper
    }
    guard !str.isEmpty else { return nil }

    var i = str.startIndex
    while i < str.endIndex {
      let next = str.unicodeScalars.index(after: i)
      let scalar = str.unicodeScalars[i]
      if self.hasBreak(before: scalar) {
        return i ..< next
      }
      i = next
    }
    return nil
  }
}

@available(macOS 26, *)
extension _CharacterRecognizer {
  init(partialCharacter: UTF8Span) {
    self.init()
    
    guard !partialCharacter.isEmpty else {
      return
    }
    
    var iter = partialCharacter.makeUnicodeScalarIterator()
    _ = hasBreak(before: iter.next().unsafelyUnwrapped)
    
    while let s = iter.next() {
      let b = hasBreak(before: s)
      assert(!b)
    }
  }

  mutating func consumePartialCharacter(_ span: UTF8Span) {
    var iter = span.makeUnicodeScalarIterator()
    
    while let s = iter.next() {
      let b = hasBreak(before: s)
      assert(!b)
    }
  }
  
  mutating func consumeUntilFirstBreak(
    in s: Substring.UnicodeScalarView,
    from i: inout String.Index
  ) -> String.Index? {
    while i < s.endIndex {
      defer { s.formIndex(after: &i) }
      if hasBreak(before: s[i]) {
        return i
      }
    }
    return nil
  }
  
  init(consuming str: some StringProtocol) {
    self.init()
    _ = self.consume(str)
  }
  
  mutating func consume(
    _ s: some StringProtocol
  ) -> (characters: Int, firstBreak: String.Index, lastBreak: String.Index)? {
    consume(Substring(s))
  }
  
  mutating func consume(
    _ s: Substring
  ) -> (characters: Int, firstBreak: String.Index, lastBreak: String.Index)? {
    consume(s.unicodeScalars)
  }
  
  mutating func consume(
    _ s: Substring.UnicodeScalarView
  ) -> (characters: Int, firstBreak: String.Index, lastBreak: String.Index)? {
    var i = s.startIndex
    guard let first = consumeUntilFirstBreak(in: s, from: &i) else {
      return nil
    }
    var characters = 1
    var last = first
    while let next = consumeUntilFirstBreak(in: s, from: &i) {
      characters += 1
      last = next
    }
    return (characters, first, last)
  }
  
  mutating func consumeUntilFirstBreak(
    _ c: BigString._Chunk,
    in range: Range<BigString._Chunk.Index>,
    from i: inout BigString._Chunk.Index
  ) -> BigString._Chunk.Index? {
    while i < range.upperBound {
      defer {
        i = c.scalarIndex(after: i)
      }
      if hasBreak(before: c[scalar: i]) {
        return i
      }
    }
    return nil
  }
  
  mutating func consume(
    _ chunk: BigString._Chunk,
    _ range: Range<BigString._Chunk.Index>
  ) -> (characters: Int, firstBreak: BigString._Chunk.Index, lastBreak: BigString._Chunk.Index)? {
    var i = range.lowerBound
    
    guard let first = consumeUntilFirstBreak(chunk, in: range, from: &i) else {
      return nil
    }
    
    var characters = 1
    var last = first
    
    while let next = consumeUntilFirstBreak(chunk, in: range, from: &i) {
      characters += 1
      last = next
    }
    
    return (characters, first, last)
  }
  
  mutating func consume(
    _ chunk: BigString._Chunk, upTo index: String.Index
  ) -> (firstBreak: String.Index, prevBreak: String.Index)? {
//    let index = chunk.unicodeScalars._index(roundingDown: index)
//    let first = chunk.firstBreak
//    guard index > first else {
//      consumePartialCharacter(chunk.string[..<index])
//      return nil
//    }
//    let last = chunk.lastBreak
//    let prev = index <= last ? chunk.string[first...].index(before: index) : last
//    consumePartialCharacter(chunk.string[prev..<index])
//    return (first, prev)
    fatalError("FIXME")
  }
  
//  mutating func edgeCounts(
//    consuming s: String
//  ) -> (characters: Int, prefixCount: Int, suffixCount: Int) {
//    let c = s.utf8.count
//    guard let (chars, first, last) = consume(s[...]) else {
//      return (0, c, c)
//    }
//    let prefix = s._utf8Offset(of: first)
//    let suffix = c - s._utf8Offset(of: last)
//    return (chars, prefix, suffix)
//  }
}

#endif
