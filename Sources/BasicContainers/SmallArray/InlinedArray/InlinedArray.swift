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
public struct InlinedArray<Element: ~Copyable, let bytes: Int>: ~Copyable {
  @usableFromInline
  internal var _count = 0
  
  @usableFromInline
  internal var _storage: [bytes of UInt8]
  
  deinit {
    // FIXME: There's a compiler bug somewhere, just tell it to shutup
    let storage = _overrideLifetime(_storage, copying: ())
    
    // FIXME: This assumes `BitwiseMovable` because we are copying the storage
    //        bytes on the stack here to get the address for deinitialization.
    storage.span.withUnsafeBytes {
      let mutableBuffer = UnsafeMutableRawBufferPointer(mutating: $0)
      let typedBuffer = mutableBuffer.assumingMemoryBound(to: Element.self)
      let occupiedItems = typedBuffer.extracting(Range(uncheckedBounds: (0, _count)))
      
      occupiedItems.deinitialize()
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension InlinedArray where Element: ~Copyable {
  /// The number of elements in this array.
  ///
  /// - Complexity: O(1)
  @export(implementation)
  @_transparent
  public var count: Int {
    _assumeNonNegative(_count)
  }
  
  /// The maximum number of elements this inlined array can hold.
  ///
  /// - Complexity: O(1)
  @export(implementation)
  @_transparent
  public var capacity: Int {
    _assumeNonNegative(bytes / MemoryLayout<Element>.stride)
  }

  /// The number of additional elements that can be added to this array without
  /// exceeding its storage capacity.
  ///
  /// - Complexity: O(1)
  @export(implementation)
  @_transparent
  public var freeCapacity: Int {
    _assumeNonNegative(capacity &- _count)
  }

  /// A Boolean value indicating whether this inlined array is fully populated.
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
