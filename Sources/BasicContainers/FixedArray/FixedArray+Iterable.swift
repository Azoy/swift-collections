//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import SpanPreview
#endif

#if compiler(>=6.2)

@available(SwiftStdlib 6.2, *)
extension FixedArray where Element: ~Copyable {
  @export(implementation)
  public var underestimatedCount: Int {
    count
  }
}

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension FixedArray: Iterable where Element: ~Copyable {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator

  @export(implementation)
  @_transparent
  public func makeBorrowingIterator() -> BorrowingIterator {
    span._makeBorrowingIterator(from: 0, to: count)
  }
}
#endif

#endif
