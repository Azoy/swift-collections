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
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @unsafe
  internal mutating func _appendUnchecked(_ newItem: consuming Element) {
    _freeSpace.initializeElement(at: 0, to: newItem)
    _count += 1
  }
  
  /// Adds an element to the end of the array.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this triggers a runtime error.
  ///
  /// - Parameter item: The element to append to the collection.
  ///
  /// - Complexity: O(1)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public mutating func append(_ newItem: consuming Element) {
    precondition(!isFull, "InlinedArray capacity overflow")
    unsafe _appendUnchecked(newItem)
  }
  
  /// Adds an element to the end of the array, if possible.
  ///
  /// If the array does not have sufficient capacity to hold any more elements,
  /// then this returns the given item without appending it; otherwise it
  /// returns nil.
  ///
  /// - Parameter item: The element to append to the array.
  /// - Returns: `item` if the array is full; otherwise nil.
  ///
  /// - Complexity: O(1)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public mutating func pushLast(_ item: consuming Element) -> Element? {
    if isFull { return item }
    unsafe _appendUnchecked(item)
    return nil
  }
}

@available(SwiftStdlib 6.2, *)
extension FixedArray where Element: ~Copyable {
  /// Append a given number of items to the end of this array by populating
  /// an output span.
  ///
  /// If the array does not have sufficient capacity to store the new items in
  /// the buffer, then this triggers a runtime error.
  ///
  /// If the callback fails to fully populate its output span or if
  /// it throws an error, then the array keeps all items that were
  /// successfully initialized before the callback terminated the insertion.
  ///
  /// - Parameters:
  ///    - newItemCount: The number of items to append to the array.
  ///    - initializer: A callback that gets called at most once to directly
  ///       populate newly reserved storage within the array. The function
  ///       is allowed to initialize fewer than `newItemCount` items.
  ///       The array is appended however many items the callback adds to
  ///       the output span before it returns (or before it throws an error).
  ///
  /// - Complexity: O(`newItemCount`)
  @_alwaysEmitIntoClient
  public mutating func append<E: Error>(
    addingCount newItemCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) {
    precondition(newItemCount >= 0, "Cannot add a negative number of items")
    precondition(freeCapacity >= newItemCount, "FixedArray capacity overflow")
    let buffer = _freeSpace._extracting(first: newItemCount)
    var span = OutputSpan(buffer: buffer, initializedCount: 0)
    defer {
      _count &+= span.finalize(for: buffer)
      span = OutputSpan()
    }
    return try initializer(&span)
  }
}

@available(SwiftStdlib 6.2, *)
extension FixedArray where Element: ~Copyable {
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @unsafe
  internal mutating func _appendUnchecked(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    guard items.count > 0 else { return }
    let c = unsafe _freeSpace._moveInitializePrefix(from: items)
    assert(c == items.count)
    _count &+= items.count
  }

  /// Moves the elements of a buffer to the end of this array, leaving the
  /// buffer uninitialized.
  ///
  /// If the array does not have sufficient capacity to hold all items in the
  /// buffer, then this triggers a runtime error.
  ///
  /// - Parameters:
  ///    - items: A fully initialized buffer whose contents to move into
  ///        the array.
  ///
  /// - Complexity: O(`items.count`)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public mutating func append(
    moving items: UnsafeMutableBufferPointer<Element>
  ) {
    precondition(items.count <= freeCapacity, "FixedArray capacity overflow")
    unsafe _appendUnchecked(moving: items)
  }

  /// Moves the elements of an output span to the end of this array, leaving the
  /// span empty.
  ///
  /// If the array does not have sufficient capacity to hold all items in its
  /// storage, then this triggers a runtime error.
  ///
  /// - Parameters:
  ///    - items: An output span whose contents need to be appended to this array.
  ///
  /// - Complexity: O(`items.count`)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public mutating func append(
    moving items: inout OutputSpan<Element>
  ) {
    // FIXME: Remove this when `OutputSpan` starts conforming to RangeReplaceableContainer
    precondition(items.count <= freeCapacity, "FixedArray capacity overflow")
    items.withUnsafeMutableBufferPointer { buffer, count in
      let source = buffer._extracting(first: count)
      unsafe _appendUnchecked(moving: source)
      count = 0
    }
  }
}
