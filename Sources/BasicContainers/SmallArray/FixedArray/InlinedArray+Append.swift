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
extension InlinedArray where Element: ~Copyable {
  @export(implementation)
  internal mutating func _appendUnchecked(_ newItem: consuming Element) {
    _freeSpace.initializeElement(at: 0, to: newItem)
    _count += 1
  }
  
  @export(implementation)
  public mutating func append(_ newItem: consuming Element) {
    precondition(!isFull, "InlinedArray capacity overflow")
    _appendUnchecked(newItem)
  }
}
