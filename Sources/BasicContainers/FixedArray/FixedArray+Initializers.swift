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
extension FixedArray where Element: ~Copyable {
  /// Creates a new array with the specified capacity, directly initializing
  /// its storage using an output span.
  ///
  /// - Parameters:
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

@available(SwiftStdlib 6.2, *)
extension FixedArray where Element: Copyable {
  /// Creates a new array containing the specified number of a single,
  /// repeated value.
  ///
  /// - Parameters:
  ///   - repeatedValue: The element to repeat.
  ///   - count: The number of times to repeat the value passed in the
  ///     `repeating` parameter. `count` must be zero or greater and less than
  ///     or equal to `capacity`.
  ///
  /// - Complexity: O(`count`)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public init(repeating repeatedValue: Element, count: Int = capacity) {
    self.init()
    let upper = Swift.min(count, capacity)
    _storage.buffer.extracting(0 ..< upper).initialize(repeating: repeatedValue)
    _count = upper
  }
}

@available(SwiftStdlib 6.2, *)
extension FixedArray where Element: Copyable {
  /// Creates a new array with the specified capacity, holding a copy
  /// of the contents of a given sequence.
  ///
  /// - Parameters:
  ///   - contents: The sequence whose contents to copy into the new array.
  ///      The sequence must not contain more than `capacity` elements.
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public init(
    capacity: Int,
    copying contents: some Sequence<Element>
  ) {
    self.init()
    self.append(copying: contents)
  }

  /// Creates a new array with the specified capacity, holding a copy
  /// of the contents of a given collection.
  ///
  /// - Parameters:
  ///   - contents: The collection whose contents to copy into the new array.
  ///      The collection must not contain more than `capacity` elements.
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public init(
    copying contents: some Collection<Element>
  ) {
    self.init()
    self.append(copying: contents)
  }

  /// Creates a new array with the specified capacity, holding a copy
  /// of the contents of the given span.
  ///
  /// - Parameters:
  ///   - span: The span whose contents to copy into the new array.
  ///      The span must not contain more than `capacity` elements.
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public init(
    copying span: Span<Element>
  ) {
    self.init()
    self.append(copying: span)
  }
}
