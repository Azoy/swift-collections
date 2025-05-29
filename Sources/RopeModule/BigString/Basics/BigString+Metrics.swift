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
internal protocol _StringMetric: RopeMetric where Element == BigString._Chunk {
  func distance(
    from start: BigString._Chunk.Index,
    to end: BigString._Chunk.Index,
    in chunk: BigString._Chunk
  ) -> Int
  
  func formIndex(
    _ i: inout BigString._Chunk.Index,
    offsetBy distance: inout Int,
    in chunk: BigString._Chunk
  ) -> (found: Bool, forward: Bool)
}

@available(macOS 9999, *)
extension BigString {
  internal struct _CharacterMetric: _StringMetric {
    typealias Element = BigString._Chunk
    typealias Summary = BigString.Summary
    
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.characters
    }
    
    func distance(
      from start: BigString._Chunk.Index,
      to end: BigString._Chunk.Index,
      in chunk: BigString._Chunk
    ) -> Int {
      chunk.characterDistance(from: start, to: end)
    }
    
    func formIndex(
      _ i: inout BigString._Chunk.Index,
      offsetBy distance: inout Int,
      in chunk: BigString._Chunk
    ) -> (found: Bool, forward: Bool) {
      chunk.formCharacterIndex(&i, offsetBy: &distance)
    }
    
    func index(
      at offset: Int,
      in chunk: BigString._Chunk
    ) -> BigString._Chunk.Index {
      precondition(offset < chunk.characterCount)
      return chunk.characters.index(chunk.characters.startIndex, offsetBy: offset)
    }
  }
  
  internal struct _UnicodeScalarMetric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.unicodeScalars
    }
    
    func distance(
      from start: BigString._Chunk.Index,
      to end: BigString._Chunk.Index,
      in chunk: BigString._Chunk
    ) -> Int {
      chunk.unicodeScalars.distance(from: start, to: end)
    }
    
    func formIndex(
      _ i: inout BigString._Chunk.Index,
      offsetBy distance: inout Int,
      in chunk: BigString._Chunk
    ) -> (found: Bool, forward: Bool) {
      guard distance != 0 else {
        i = chunk.unicodeScalars.index(roundingDown: i)
        return (true, false)
      }
      if distance > 0 {
        let end = chunk.unicodeScalars.endIndex
        while distance > 0, i < end {
          chunk.unicodeScalars.formIndex(after: &i)
          distance &-= 1
        }
        return (distance == 0, true)
      }
      let start = chunk.unicodeScalars.startIndex
      while distance < 0, i > start {
        chunk.unicodeScalars.formIndex(before: &i)
        distance &+= 1
      }
      return (distance == 0, false)
    }
    
    func index(at offset: Int, in chunk: BigString._Chunk) -> BigString._Chunk.Index {
      chunk.unicodeScalars.index(chunk.unicodeScalars.startIndex, offsetBy: offset)
    }
  }
  
  internal struct _UTF8Metric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.utf8
    }
    
    func distance(
      from start: BigString._Chunk.Index,
      to end: BigString._Chunk.Index,
      in chunk: BigString._Chunk
    ) -> Int {
      chunk.utf8Distance(from: start, to: end)
    }
    
    func formIndex(
      _ i: inout BigString._Chunk.Index,
      offsetBy distance: inout Int,
      in chunk: BigString._Chunk
    ) -> (found: Bool, forward: Bool) {
      // Here we make use of the fact that the UTF-8 view of BigString._Chunk
      // has O(1) index distance & offset calculations.
      let offset = i.utf8Offset
      if distance >= 0 {
        let rest = chunk.utf8Count - offset
        if distance > rest {
          i = chunk.endIndex
          distance -= rest
          return (false, true)
        }
        i.utf8Offset += distance
        distance = 0
        return (true, true)
      }
      
      if offset + distance < 0 {
        i = chunk.startIndex
        distance += offset
        return (false, false)
      }
      i.utf8Offset += distance
      distance = 0
      return (true, false)
    }
    
    func index(at offset: Int, in chunk: BigString._Chunk) -> BigString._Chunk.Index {
      chunk.startIndex.offset(by: offset)
    }
  }
  
  internal struct _UTF16Metric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.utf16
    }
    
    func distance(
      from start: BigString._Chunk.Index,
      to end: BigString._Chunk.Index,
      in chunk: BigString._Chunk
    ) -> Int {
      chunk.utf16.distance(from: start, to: end)
    }
    
    func formIndex(
      _ i: inout BigString._Chunk.Index,
      offsetBy distance: inout Int,
      in chunk: BigString._Chunk
    ) -> (found: Bool, forward: Bool) {
      if distance >= 0 {
        if
          distance <= chunk.utf16Count,
          let r = chunk.utf16.index(
            i, offsetBy: distance, limitedBy: chunk.utf16.endIndex
          ) {
          i = r
          distance = 0
          return (true, true)
        }
        distance -= chunk.utf16.distance(from: i, to: chunk.utf16.endIndex)
        i = chunk.utf16.endIndex
        return (false, true)
      }
      
      if
        distance.magnitude <= chunk.utf16Count,
        let r = chunk.utf16.index(
          i, offsetBy: distance, limitedBy: chunk.utf16.endIndex
        ) {
        i = r
        distance = 0
        return (true, true)
      }
      distance += chunk.utf16.distance(from: chunk.utf16.startIndex, to: i)
      i = chunk.utf16.startIndex
      return (false, false)
    }
    
    func index(at offset: Int, in chunk: BigString._Chunk) -> BigString._Chunk.Index {
      chunk.utf16.index(chunk.startIndex, offsetBy: offset)
    }
  }
}

#endif
