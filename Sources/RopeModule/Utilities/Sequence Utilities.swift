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

extension Sequence {
  func nth(_ n: Int) -> Element? {
    var iter = makeIterator()

    for _ in 0 ..< n {
      guard iter.next() != nil else {
        return nil
      }
    }

    return iter.next()
  }
}
