//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2)

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 6.2, *)
extension FixedArray where Element: ~Copyable {
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public func isTriviallyIdentical(to other: borrowing Self) -> Bool {
    _storage.buffer._isIdentical(to: other._storage.buffer) && _count == other._count
  }
}

@available(SwiftStdlib 6.2, *)
extension FixedArray: Equatable where Element: Equatable & ~Copyable {
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public static func ==(
    left: borrowing Self,
    right: borrowing Self
  ) -> Bool {
    left.span._elementsEqual(to: right.span)
  }
}

#endif
