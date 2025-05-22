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
  struct CharacterView {
    var _base: BigString._Chunk

    init(_ base: BigString._Chunk) {
      self._base = base
    }
  }

  var characters: CharacterView {
    CharacterView(self)
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.CharacterView: Sequence {
  typealias Element = Character

  struct Iterator {
    var _base: BigString._Chunk
    var offset: Int
  }

  func makeIterator() -> Iterator {
    Iterator(_base: self._base, offset: self._base.prefixCount)
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.CharacterView.Iterator: IteratorProtocol {
  typealias Element = Character

  mutating func next() -> Character? {
    var iter = _base.utf8Span(from: offset).makeCharacterIterator()
    
    guard let c = iter.next() else {
      return nil
    }
    
    offset &+= c.utf8.count
    
    return c
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.CharacterView: BidirectionalCollection {
  typealias Index = BigString._Chunk.Index
  
  var startIndex: Index {
    Index(utf8Offset: _base.prefixCount).knownCharacterAligned()
  }

  var endIndex: Index {
    Index(utf8Offset: _base.utf8Count - _base.suffixCount).knownCharacterAligned()
  }

  var count: Int {
    guard _base.hasBreaks else {
      return 0
    }
    
    return _base.counts.characters
  }

  func index(after i: Index) -> Index {
    let i = index(roundingDown: i)
    var si = _base.utf8Span(from: i.utf8Offset).makeCharacterIterator()
    _ = si.skipForward()
    return Index(utf8Offset: si.currentCodeUnitOffset).knownCharacterAligned()
  }

  func index(before i: Index) -> Index {
    let i = index(roundingDown: i)
    var si = _base.utf8Span.makeCharacterIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipBack()
    return Index(utf8Offset: si.currentCodeUnitOffset).knownCharacterAligned()
  }

  subscript(index: Index) -> Character {
    precondition(index >= startIndex && index < endIndex, "Index out of bounds")
    
    var iter = _base.utf8Span(from: index.utf8Offset).makeCharacterIterator()
    return iter.next().unsafelyUnwrapped
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.CharacterView {
  func index(roundingDown i: Index) -> Index {
    precondition(_base.hasBreaks, "Chunk must have a break to round")
    
    if i.isKnownCharacterAligned || i.utf8Offset == 0 {
      return i.knownCharacterAligned()
    }
    
    if i == endIndex {
      return endIndex
    }
    
    var cr = _CharacterRecognizer()
    var scalars = _base.unicodeScalars[startIndex ..< endIndex]
    
    assert(!scalars.isEmpty)
    let s = scalars.popFirst()!
    
    _ = cr.hasBreak(before: s)
    
    var lastBreak = startIndex
    
    for (i, s) in scalars. {
      if cr.hasBreak(before: s) {
        lastBreak = i
      }
    }
  }
}

#endif
