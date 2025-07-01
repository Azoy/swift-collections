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

extension Array {
  subscript(weird i: Int) -> Element {
    get {
      if i < 0 {
        return self[count + i]
      }
      
      precondition(i < endIndex, "Index out of bounds")
      return self[i]
    }
    
    set {
      if i < 0 {
        self[count + i] = newValue
        return
      }
      
      precondition(i < endIndex, "Index out of bounds")
      self[i] = newValue
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString {
  public enum Edit {
    case insert(Range<Index>)
    case delete(Range<Index>)
    //case equal(_ChunkLine, _ChunkLine)
  }
  
  struct Box {
    var left: Int
    var right: Int
    var top: Int
    var bottom: Int
    
    var width: Int {
      right - left
    }
    
    var height: Int {
      bottom - top
    }
    
    var size: Int {
      width + height
    }
    
    var delta: Int {
      width - height
    }
  }
  
  struct Snake {
    var start: (Int, Int)
    var end: (Int, Int)
  }
  
  typealias _ChunkLine = (chunk: _Chunk, range: Range<Int>)
  typealias Trace = ([Int], Int)
}

@available(SwiftStdlib 6.2, *)
extension BigString.Box {
  func findPath(
    _ old: [BigString._ChunkLine],
    _ new: [BigString._ChunkLine]
  ) -> [(Int, Int)]? {
    guard let snake = midpoint(old, new) else {
      return nil
    }
    
    let headBox = Self(
      left: left,
      right: snake.start.0,
      top: top,
      bottom: snake.start.1
    )
    
    let tailBox = Self(
      left: snake.end.0,
      right: right,
      top: snake.end.1,
      bottom: bottom
    )
    
    let head = headBox.findPath(old, new) ?? [snake.start]
    let tail = tailBox.findPath(old, new) ?? [snake.end]
    return head + tail
  }
  
  func midpoint(
    _ old: [BigString._ChunkLine],
    _ new: [BigString._ChunkLine]
  ) -> BigString.Snake? {
    if size == 0 {
      return nil
    }
    
    let half = size / 2
    let max = if size & 1 != 0 {
      half + 1
    } else {
      half
    }
    
    var vf = [Int](repeating: 0, count: 2 * max + 1)
    vf[1] = left
    var vb = [Int](repeating: 0, count: 2 * max + 1)
    vb[1] = bottom
    
    for d in 0 ..< max + 1 {
      switch forward(&vf, vb, d, old, new) {
      case .some(let snake):
        return snake
        
      case .none:
        switch backward(vf, &vb, d, old, new) {
        case .some(let snake):
          return snake
          
        case .none:
          continue
        }
      }
    }
    
    return nil
  }
  
  func forward(
    _ forward: inout [Int],
    _ backward: [Int],
    _ depth: Int,
    _ old: [BigString._ChunkLine],
    _ new: [BigString._ChunkLine]
  ) -> BigString.Snake? {
    for k in stride(from: depth, through: -depth, by: -2) {
      let c = k - delta
      var x = 0
      var px = 0
      
      if k == -depth || (k != depth && forward[weird: k - 1] < forward[weird: k + 1]) {
        x = forward[weird: k + 1]
        px = x
      } else {
        px = forward[weird: k - 1]
        x = px + 1
      }
      
      var y = top + (x - left) - k
      let py = if depth == 0 || x != px {
        y
      } else {
        y - 1
      }
      
      while x < right, y < bottom, old[x].chunk.storage === new[y].chunk.storage {
        x += 1
        y += 1
      }
      
      forward[weird: k] = x
      
      if delta & 1 != 0, (c >= -(depth - 1) && c <= depth - 1), y >= backward[weird: c] {
        return BigString.Snake(start: (px, py), end: (x, y))
      }
    }
    
    return nil
  }
  
  func backward(
    _ forward: [Int],
    _ backward: inout [Int],
    _ depth: Int,
    _ old: [BigString._ChunkLine],
    _ new: [BigString._ChunkLine]
  ) -> BigString.Snake? {
    for c in stride(from: depth, through: -depth, by: -2) {
      let k = c + delta
      var y = 0
      var py = 0
      
      if c == -depth || (c != depth && backward[weird: c - 1] > forward[weird: c + 1]) {
        y = backward[weird: c + 1]
        py = y
      } else {
        py = backward[weird: c - 1]
        y = py - 1
      }
      
      var x = left + (y - top) + k
      let px = if depth == 0 || y != py {
        x
      } else {
        x + 1
      }
      
      while x > left, y > top, old[x - 1].chunk.storage === new[y - 1].chunk.storage {
        x -= 1
        y -= 1
      }
      
      backward[weird: c] = y
      
      if delta & 1 == 0, (k >= -depth && k <= depth), x <= forward[weird: k] {
        return BigString.Snake(start: (x, y), end: (px, py))
      }
    }
    
    return nil
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString {
  func walk(
    _ old: [_ChunkLine],
    _ new: [_ChunkLine]
  ) -> [Edit] {
    var edits: [Edit] = []
    let box = Box(left: 0, right: old.count, top: 0, bottom: new.count)
    
    guard let path = box.findPath(old, new) else {
      return edits
    }
    
    for i in path.indices {
      guard i != path.endIndex && i + 1 != path.endIndex else {
        break
      }
      
      var (x1, y1) = path[i]
      let (x2, y2) = path[i + 1]
      
      (x1, y1) = walkDiag(old, new, x1, y1, x2, y2, &edits)
      
      let xDiff = x2 - x1
      let yDiff = y2 - y1
      
      if xDiff < yDiff {
        let chunkLine = new[y1]
        let low = Index(_utf8Offset: chunkLine.range.lowerBound)
        let high = Index(_utf8Offset: chunkLine.range.upperBound)
        edits.append(.insert(low ..< high))
        y1 += 1
      }
      
      if xDiff > yDiff {
        let chunkLine = old[x1]
        let low = Index(_utf8Offset: chunkLine.range.lowerBound)
        let high = Index(_utf8Offset: chunkLine.range.upperBound)
        edits.append(.delete(low ..< high))
        x1 += 1
      }
      
      _ = walkDiag(old, new, x1, y1, x2, y2, &edits)
    }
    
    return edits
  }
  
  func walkDiag(
    _ old: [_ChunkLine],
    _ new: [_ChunkLine],
    _ x1: Int,
    _ y1: Int,
    _ x2: Int,
    _ y2: Int,
    _ edits: inout [Edit]
  ) -> (Int, Int) {
    var x1 = x1
    var y1 = y1
    
    while x1 < x2, y1 < y2, old[x1].chunk.storage === new[y1].chunk.storage {
      if x1 == x1 + 1 {
        let chunkLine = new[y1]
        let low = Index(_utf8Offset: chunkLine.range.lowerBound)
        let high = Index(_utf8Offset: chunkLine.range.upperBound)
        edits.append(.insert(low ..< high))
      } else if y1 == y1 + 1 {
        let chunkLine = old[x1]
        let low = Index(_utf8Offset: chunkLine.range.lowerBound)
        let high = Index(_utf8Offset: chunkLine.range.upperBound)
        edits.append(.delete(low ..< high))
      }
      
      x1 += 1
      y1 += 1
    }
    
    return (x1, y1)
  }
  
  public func diff(with other: BigString) -> [Edit] {
    var selfChunks: [_ChunkLine] = []
    
    _foreachChunk {
      if selfChunks.isEmpty {
        selfChunks.append(($0, 0 ..< $0.utf8Count))
        return
      }
      
      let last = selfChunks.last!.range.upperBound
      selfChunks.append(($0, last ..< last + $0.utf8Count))
    }
    
    var otherChunks: [_ChunkLine] = []
    
    other._foreachChunk {
      if otherChunks.isEmpty {
        otherChunks.append(($0, 0 ..< $0.utf8Count))
        return
      }
      
      let last = otherChunks.last!.range.upperBound
      otherChunks.append(($0, last ..< last + $0.utf8Count))
    }
    
    return walk(selfChunks, otherChunks)
  }
}
