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

import Builtin

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 6.2, *)
@frozen
public struct InlinedArray<let capacity: Int, Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _count: Int
  
  @usableFromInline
  internal var _storage = _Storage()
  
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @_transparent
  public init() {
    _count = 0
  }
  
  // FIXME: We assume 'BitwiseMovable'
  // move init() { ... }
  
  @export(implementation)
  @_transparent
  deinit {
    _items.deinitialize()
  }
}

@available(SwiftStdlib 6.2, *)
extension InlinedArray: Sendable where Element: ~Copyable & Sendable {}

@available(SwiftStdlib 6.2, *)
extension InlinedArray where Element: ~Copyable {
  @usableFromInline
  @_rawLayout(likeArrayOf: Element, count: capacity)
  internal struct _Storage: ~Copyable {
    // This returns a buffer over the entire storage, even if 'count' elements
    // are not initialized. You should almost never call this.
    @available(SwiftStdlib 6.2, *)
    @export(implementation)
    @_transparent
    internal var buffer: UnsafeMutableBufferPointer<Element> {
      let rawPointer = Builtin.addressOfRawLayout(self)
      let pointer = UnsafeMutablePointer<Element>(rawPointer)
      return UnsafeMutableBufferPointer(start: pointer, count: capacity)
    }
    
    @available(SwiftStdlib 6.2, *)
    @export(implementation)
    @_transparent
    internal init() {}
  }
}

@available(SwiftStdlib 6.2, *)
extension InlinedArray._Storage: @unchecked Sendable where Element: ~Copyable & Sendable {}

@available(SwiftStdlib 6.2, *)
extension InlinedArray where Element: ~Copyable {
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @_transparent
  internal var _items: UnsafeMutableBufferPointer<Element> {
    _storage.buffer.extracting(Range(uncheckedBounds: (0, count)))
  }
  
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @_transparent
  internal var _freeSpace: UnsafeMutableBufferPointer<Element> {
    _storage.buffer.extracting(Range(uncheckedBounds: (count, capacity)))
  }
  
  /// The maximum number of elements this inlined array can hold.
  ///
  /// - Complexity: O(1)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @_transparent
  public var capacity: Int {
    _assumeNonNegative(capacity)
  }

  /// The number of additional elements that can be added to this array without
  /// exceeding its storage capacity.
  ///
  /// - Complexity: O(1)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @_transparent
  public var freeCapacity: Int {
    _assumeNonNegative(capacity &- count)
  }

  /// A Boolean value indicating whether this inlined array is fully populated.
  ///
  /// If this property returns true, then the array's storage is at capacity,
  /// and it cannot accommodate any additional elements.
  ///
  /// - Complexity: O(1)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @_transparent
  public var isFull: Bool {
    freeCapacity == 0
  }
}

@available(SwiftStdlib 6.2, *)
extension InlinedArray where Element: ~Copyable {
  /// A span over the elements of this array, providing direct read-only access.
  ///
  /// - Complexity: O(1)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public var span: Span<Element> {
    @_lifetime(borrow self)
    @_transparent
    get {
      let result = unsafe Span(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, borrowing: self)
    }
  }
  
  /// A mutable span over the elements of this array, providing direct
  /// mutating access.
  ///
  /// - Complexity: O(1)
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public var mutableSpan: MutableSpan<Element> {
    @_lifetime(&self)
    @_transparent
    mutating get {
      let result = unsafe MutableSpan(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, mutating: &self)
    }
  }
  
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @_lifetime(borrow self)
  @_transparent
  internal func _span(in range: Range<Int>) -> Span<Element> {
    span.extracting(range)
  }

  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  @_lifetime(&self)
  @_transparent
  internal mutating func _mutableSpan(
    in range: Range<Int>
  ) -> MutableSpan<Element> {
    let result = unsafe MutableSpan(_unsafeElements: _items.extracting(range))
    return unsafe _overrideLifetime(result, mutating: &self)
  }
}

@available(SwiftStdlib 6.2, *)
extension InlinedArray where Element: ~Copyable {
  /// Arbitrarily edit the storage underlying this array by invoking a
  /// user-supplied closure with a mutable `OutputSpan` view over it.
  ///
  /// This method calls its function argument at most once, allowing it to
  /// arbitrarily modify the contents of the output span it is given.
  /// The argument is free to add, remove or reorder any items; however,
  /// it is not allowed to replace the span or change its capacity.
  ///
  /// When the function argument finishes (whether by returning or throwing an
  /// error) the rigid array instance is updated to match the final contents of
  /// the output span.
  ///
  /// - Parameter body: A function that edits the contents of this array through
  ///    an `OutputSpan` argument. This method invokes this function
  ///    at most once.
  /// - Returns: This method returns the result of its function argument.
  /// - Complexity: Adds O(1) overhead to the complexity of the function
  ///    argument.
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  public mutating func edit<E: Error, R: ~Copyable>(
    _ body: (inout OutputSpan<Element>) throws(E) -> R
  ) throws(E) -> R {
    var span = OutputSpan(buffer: _storage.buffer, initializedCount: count)
    defer {
      _count = span.finalize(for: _storage.buffer)
      span = OutputSpan()
    }
    return try body(&span)
  }
}

@available(SwiftStdlib 6.2, *)
extension InlinedArray where Element: ~Copyable {
  @available(SwiftStdlib 6.2, *)
  @export(implementation)
  internal mutating func _closeGap(
    at index: Int,
    count: Int
  ) {
    guard count > 0 else { return }
    let source = unsafe _items.extracting(
      Range(uncheckedBounds: (index + count, _count)))
    let target = unsafe _items.extracting(
      Range(uncheckedBounds: (index, index + source.count)))
    let i = unsafe target.moveInitialize(fromContentsOf: source)
    assert(i == target.endIndex)
  }
}
