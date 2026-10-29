//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 6.2, *)
extension SmallArray where Element: ~Copyable {
  @export(implementation)
  public mutating func append(_ newItem: consuming Element) {
    // FIXME: We have to spell out the switch for any appends because we don't
    //        have `@once` closures yet.
    let c = count
    switch consume self {
    case .small(var s):
      guard s.isFull else {
        s._appendUnchecked(newItem)
        self = .small(s)
        return
      }
      
      var u = UniqueArray<Element>(minimumCapacity: c + 1)
      
      s.consumeForEach {
        u.append($0)
      }
      
      u.append(newItem)
      
      self = .large(u)
      
    case .large(var l):
      l.append(newItem)
      self = .large(l)
    }
  }
}
