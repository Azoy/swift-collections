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
extension BigString._Chunk {
  @inline(__always)
  var hasBreaks: Bool { counts.hasBreaks }

  var firstBreak: Index {
    characters.startIndex
  }

  var lastBreak: Index {
    characters.endIndex
  }
  
  var prefix: Swift.Slice<UnicodeScalarView> { unicodeScalars[..<firstBreak] }
  var suffix: Swift.Slice<UnicodeScalarView> { unicodeScalars[lastBreak...] }
}

@available(macOS 9999, *)
extension BigString._Chunk {
  var immediateLastBreakState: _CharacterRecognizer? {
    guard hasBreaks else { return nil }
    return _CharacterRecognizer(partialCharacter: unicodeScalars[lastBreak...])
  }

  func nearestBreak(before index: Index) -> Index? {
    let index = unicodeScalars.index(roundingDown: index)
    let first = firstBreak
    guard index > first else { return nil }
    let last = lastBreak
    guard index <= last else { return last }
    let rounded = characters.index(roundingDown: index)
    guard rounded == index else { return rounded }
    return characters.index(before: rounded)
  }

  func immediateBreakState(
    upTo index: Index
  ) -> (prevBreak: Index, state: _CharacterRecognizer)? {
    guard let prev = nearestBreak(before: index) else { return nil }
    let state = _CharacterRecognizer(partialCharacter: unicodeScalars[prev..<index])
    return (prev, state)
  }
}

#endif
