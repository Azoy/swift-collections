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
extension BigString._Chunk.CharacterView: BidirectionalCollection {
  typealias Index = BigString._Chunk.Index
  
  var startIndex: Index {
    Index(utf8Offset: _base.prefixCount).characterAligned
  }

  var endIndex: Index {
    Index(utf8Offset: _base.utf8Count - _base.suffixCount).characterAligned
  }

  var count: Int {
    guard _base.hasBreaks else {
      return 0
    }
    
    return _base.counts.characters
  }

  func index(after i: Index) -> Index {
    let i = index(roundingDown: i)
    var si = _base.utf8Span.makeCharacterIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipForward()
    return Index(utf8Offset: si.currentCodeUnitOffset).characterAligned
  }

  func index(before i: Index) -> Index {
    let i = index(roundingDown: i)
    var si = _base.utf8Span.makeCharacterIterator()
    si.reset(toUnchecked: i.utf8Offset)
    _ = si.skipBack()
    return Index(utf8Offset: si.currentCodeUnitOffset).characterAligned
  }

  subscript(index: Index) -> Character {
    precondition(index >= startIndex && index < endIndex, "Index out of bounds")
    
    var iter = _base.utf8Span.makeCharacterIterator()
    iter.reset(toUnchecked: index.utf8Offset)
    return iter.next().unsafelyUnwrapped
  }
}

@available(macOS 9999, *)
extension BigString._Chunk.CharacterView {
  func index(roundingDown i: Index) -> Index {
    precondition(_base.hasBreaks, "Chunk must have a break to round")
    
    if i.isKnownCharacterAligned || i.utf8Offset == 0 {
      return i.characterAligned
    }
    
    if i == endIndex {
      return endIndex
    }
    
    var iter = _base.utf8Span.makeCharacterIterator()
    iter.reset(toUnchecked: i.utf8Offset)
    _ = iter.skipBack()
    _ = iter.skipForward()
    return Index(utf8Offset: iter.currentCodeUnitOffset).characterAligned
    
//    var cr = _CharacterRecognizer()
//    var scalars = _base.unicodeScalars[startIndex ..< endIndex]
//    
//    guard let s = scalars.popFirst() else {
//      return endIndex
//    }
//    
//    _ = cr.hasBreak(before: s)
//    
//    var j = scalars.startIndex
//    var lastBreak = startIndex
//    
//    while j < i {
//      let s = scalars[j]
//      
//      if cr.hasBreak(before: s) {
//        lastBreak = j
//      }
//      
//      j = Index(utf8Offset: j.utf8Offset + s.utf8.count).scalarAligned
//    }
//    
//    return lastBreak
  }
}

#endif
