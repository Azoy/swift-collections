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
@frozen
public enum SmallArray<let capacity: Int, Element: ~Copyable>: ~Copyable {
  case small(InlinedArray<capacity, Element>)
  case large(UniqueArray<Element>)
}

@available(SwiftStdlib 6.2, *)
extension SmallArray: Sendable where Element: Sendable {}

@available(SwiftStdlib 6.2, *)
extension SmallArray where Element: ~Copyable {
  @export(implementation)
  internal func _borrow<R: ~Copyable, E: Error>(
    small: (borrowing InlinedArray<capacity, Element>) throws(E) -> R,
    large: (borrowing UniqueArray<Element>) throws(E) -> R
  ) throws(E) -> R {
    switch self {
    case .small(let s):
      try small(s)
    case .large(let l):
      try large(l)
    }
  }
  
  // Note: You cannot perform any resizing operations in the small case.
  @export(implementation)
  internal mutating func _mutate<R: ~Copyable, E: Error>(
    small: (inout InlinedArray<capacity, Element>) throws(E) -> R,
    large: (inout UniqueArray<Element>) throws(E) -> R
  ) throws(E) -> R {
    switch consume self {
    case .small(var s):
      do {
        let r = try small(&s)
        self = .small(s)
        return r
      } catch {
        self = .small(s)
        throw error
      }
    case .large(var l):
      do {
        let r = try large(&l)
        self = .large(l)
        return r
      } catch {
        self = .large(l)
        throw error
      }
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension SmallArray where Element: ~Copyable {
  @export(implementation)
  internal var _items: UnsafeMutableBufferPointer<Element> {
    _borrow(
      small: { $0._items },
      large: { $0._storage._items }
    )
  }
  
  @export(implementation)
  internal var _freeSpace: UnsafeMutableBufferPointer<Element> {
    _borrow(
      small: { $0._freeSpace },
      large: { $0._storage._freeSpace }
    )
  }
  
  @export(implementation)
  internal var _smallIsFull: Bool {
    _borrow(
      small: { $0.isFull },
      large: { _ in false }
    )
  }
}

@available(SwiftStdlib 6.2, *)
extension SmallArray where Element: ~Copyable {
  /// The maximum number of elements this rigid array can hold.
  ///
  /// - Complexity: O(1)
  @export(implementation)
  @_transparent
  public var capacity: Int {
    _assumeNonNegative(
      _borrow(
        small: { _ in capacity },
        large: { $0.capacity }
      )
    )
  }

  /// The number of additional elements that can be added to this array without
  /// exceeding its storage capacity.
  ///
  /// - Complexity: O(1)
  @export(implementation)
  @_transparent
  public var freeCapacity: Int {
    _assumeNonNegative(
      _borrow(
        small: { $0.freeCapacity },
        large: { $0.freeCapacity }
      )
    )
  }

  /// A Boolean value indicating whether this rigid array is fully populated.
  ///
  /// If this property returns true, then the array's storage is at capacity,
  /// and it cannot accommodate any additional elements.
  ///
  /// - Complexity: O(1)
  @export(implementation)
  @_transparent
  public var isFull: Bool {
    freeCapacity == 0
  }
}

@available(SwiftStdlib 6.2, *)
extension SmallArray where Element: ~Copyable {
  /// A span over the elements of this array, providing direct read-only access.
  ///
  /// - Complexity: O(1)
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
  @export(implementation)
  public var mutableSpan: MutableSpan<Element> {
    @_lifetime(&self)
    @_transparent
    mutating get {
      let result = unsafe MutableSpan(_unsafeElements: _items)
      return unsafe _overrideLifetime(result, mutating: &self)
    }
  }

  @inlinable
  @_lifetime(borrow self)
  internal func _span(in range: Range<Int>) -> Span<Element> {
    span.extracting(range)
  }

  @inlinable
  @_lifetime(&self)
  internal mutating func _mutableSpan(
    in range: Range<Int>
  ) -> MutableSpan<Element> {
    let result = unsafe MutableSpan(_unsafeElements: _items.extracting(range))
    return unsafe _overrideLifetime(result, mutating: &self)
  }
}

@available(SwiftStdlib 6.2, *)
extension SmallArray where Element: ~Copyable {
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
    switch consume self {
    case .small(var s):
      do {
        let r = try s.edit(body)
        self = .small(s)
        return r
      } catch {
        self = .small(s)
        throw error
      }
    case .large(var l):
      do {
        let r = try l.edit(body)
        self = .large(l)
        return r
      } catch {
        self = .large(l)
        throw error
      }
    }
  }
}
