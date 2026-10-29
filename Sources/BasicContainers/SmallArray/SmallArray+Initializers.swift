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
  /// Initializes a new small array with no elements.
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public init() {
    self = .small(.init())
  }
  
  /// Initializes a new small array with the specified capacity and no elements.
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public init(minimumCapacity: Int) {
    if minimumCapacity > capacity {
      self = .large(.init(minimumCapacity: minimumCapacity))
      return
    }
    
    self = .small(.init())
  }
}

@available(SwiftStdlib 6.2, *)
extension SmallArray where Element: ~Copyable {
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
    capacity c: Int = capacity,
    initializingWith body: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    self.init(minimumCapacity: c)
    try edit(body)
  }
}

@available(SwiftStdlib 6.2, *)
extension SmallArray where Element: Copyable {
  @available(SwiftStdlib 6.2, *)
  public init(repeating repeatedValue: Element, count c: Int = capacity) {
    guard c <= capacity else {
      self = .large(.init(repeating: repeatedValue, count: c))
      return
    }
    
    self = .small(.init(repeating: repeatedValue, count: c))
  }
}
