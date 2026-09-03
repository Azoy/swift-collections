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

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension RigidArray {
  /// Copy the contents of this array into a newly allocated rigid array
  /// instance with just enough capacity to hold all its elements.
  ///
  /// - Complexity: O(`count`)
  @_alwaysEmitIntoClient
  public func clone() -> Self {
    clone(capacity: self.count)
  }

  /// Copy the contents of this array into a newly allocated rigid array
  /// instance with the specified capacity.
  ///
  /// - Parameter capacity: The desired capacity of the resulting rigid array.
  ///    `capacity` must be greater than or equal to `count`.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public func clone(capacity: Int) -> Self {
    precondition(capacity >= count, "RigidArray capacity overflow")
    var result = RigidArray<Element>(capacity: capacity)
    let initialized = unsafe result._storage.initialize(fromContentsOf: _items)
    precondition(initialized == count)
    result._count = count
    return result
  }
}

#endif
