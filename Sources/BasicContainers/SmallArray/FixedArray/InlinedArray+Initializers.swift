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
extension InlinedArray where Element: Copyable {
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public init(repeating repeatedValue: Element, count: Int = capacity) {
    _storage.buffer.extracting(0 ..< count).initialize(repeating: repeatedValue)
    _count = count
  }
}

@available(SwiftStdlib 6.2, *)
extension InlinedArray where Element: ~Copyable {
  /// Creates a new array with the specified capacity, directly initializing
  /// its storage using an output span.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new array.
  ///   - body: A callback that gets called at most once to directly
  ///       populate newly reserved storage within the array. The function
  ///       is allowed to add fewer than `capacity` items. The array is
  ///       initialized with however many items the callback adds to the
  ///       output span before it returns (or before it throws an error).
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public init<E: Error>(
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init()
    try edit(body)
  }
}
