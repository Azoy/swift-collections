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
  /// Removes and returns the element at the specified position.
  ///
  /// All the elements following the specified position are moved to close the
  /// gap.
  ///
  /// - Parameter index: The position of the element to remove. `index` must be
  ///   a valid index of the array that is not equal to the end index.
  /// - Returns: The removed element.
  ///
  /// - Complexity: O(`count`)
  @discardableResult
  @export(implementation)
  public mutating func remove(at index: Int) -> Element {
    _checkItemIndex(index)
    let old = unsafe _items.moveElement(from: index)
    _closeGap(at: index, count: 1)
    _count -= 1
    return old
  }
}
