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

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import SpanPreview
import ContainersPreview
import BasicContainers
#endif

#if compiler(>=6.2)

@available(SwiftStdlib 6.2, *)
private func expectSmallVariant<let capacity: Int, Element: ~Copyable>(
  _ sa: borrowing SmallArray<capacity, Element>,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  switch sa {
  case .small(_):
    return
    
  case .large(_):
    _expectFailure(
      "Expected small variant of SmallArray",
      message,
      trapping: trapping,
      file: file,
      line: line
    )
  }
}

@available(SwiftStdlib 6.2, *)
private func expectLargeVariant<let capacity: Int, Element: ~Copyable>(
  _ sa: borrowing SmallArray<capacity, Element>,
  _ message: @autoclosure () -> String = "",
  trapping: Bool = false,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  switch sa {
  case .small(_):
    _expectFailure(
      "Expected large variant of SmallArray",
      message,
      trapping: trapping,
      file: file,
      line: line
    )
    
  case .large(_):
    return
  }
}

@available(SwiftStdlib 6.2, *)
class SmallArrayTests: CollectionTestCase {
  func test_memory_layout() {
    let word = MemoryLayout<Int>.size
    
    // The inline int overlaps either the ptr or capacity from the UniqueArray
    expectEqual(MemoryLayout<SmallArray<1, Int>>.stride, 4 * word)
    expectEqual(MemoryLayout<SmallArray<1, Int>?>.stride, 4 * word)
    
    // The 2 inline ints overlap the ptr and capacity from the UniqueArray
    expectEqual(MemoryLayout<SmallArray<2, Int>>.stride, 4 * word)
    expectEqual(MemoryLayout<SmallArray<2, Int>?>.stride, 4 * word)
    
    // The additional 3rd inline int needs extra storage
    expectEqual(MemoryLayout<SmallArray<3, Int>>.stride, 5 * word)
    expectEqual(MemoryLayout<SmallArray<3, Int>?>.stride, 5 * word)
  }
  
  func test_small_basics() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      var array = SmallArray<2, Value>()
      expectTrue(array.isEmpty)
      expectEqual(array.count, 0)
      expectEqual(array.capacity, 2)
      expectEqual(tracker.instances, 0)
      expectSmallVariant(array)

      array.append(tracker.structInstance(for: 10))
      expectFalse(array.isEmpty)
      expectEqual(array.count, 1)
      expectEqual(array.capacity, 2)
      expectEqual(array[0].payload, 10)
      expectEqual(tracker.instances, 1)
      expectSmallVariant(array)

      array.append(tracker.structInstance(for: 20))
      expectFalse(array.isEmpty)
      expectEqual(array.count, 2)
      expectEqual(array.capacity, 2) // This assumes a specific growth behavior
      expectEqual(array[0].payload, 10)
      expectEqual(array[1].payload, 20)
      expectEqual(tracker.instances, 2)
      expectSmallVariant(array)

      let old = array.remove(at: 0)
      expectEqual(old.payload, 10)
      expectFalse(array.isEmpty)
      expectEqual(array.count, 1)
      expectEqual(array.capacity, 2)
      expectEqual(array[0].payload, 20)
      expectEqual(tracker.instances, 2)
      _ = consume old
      expectEqual(tracker.instances, 1)
      expectSmallVariant(array)

      let old2 = array.remove(at: 0)
      expectEqual(old2.payload, 20)
      expectEqual(array.count, 0)
      expectEqual(array.capacity, 2)
      expectTrue(array.isEmpty)
      expectEqual(tracker.instances, 1)
      _ = consume old2
      expectEqual(tracker.instances, 0)
      expectSmallVariant(array)
    }
  }
  
  func test_large_basics() {
    withLifetimeTracking { tracker in
      typealias Value = LifetimeTrackedStruct<Int>

      var array = SmallArray<0, Value>()
      expectTrue(array.isEmpty)
      expectEqual(array.count, 0)
      expectEqual(array.capacity, 0)
      expectEqual(tracker.instances, 0)
      expectSmallVariant(array)

      array.append(tracker.structInstance(for: 10))
      expectFalse(array.isEmpty)
      expectEqual(array.count, 1)
      expectEqual(array.capacity, 1)
      expectEqual(array[0].payload, 10)
      expectEqual(tracker.instances, 1)
      expectLargeVariant(array)

      array.append(tracker.structInstance(for: 20))
      expectFalse(array.isEmpty)
      expectEqual(array.count, 2)
      expectEqual(array.capacity, 2) // This assumes a specific growth behavior
      expectEqual(array[0].payload, 10)
      expectEqual(array[1].payload, 20)
      expectEqual(tracker.instances, 2)
      expectLargeVariant(array)

      let old = array.remove(at: 0)
      expectEqual(old.payload, 10)
      expectFalse(array.isEmpty)
      expectEqual(array.count, 1)
      expectEqual(array.capacity, 2)
      expectEqual(array[0].payload, 20)
      expectEqual(tracker.instances, 2)
      _ = consume old
      expectEqual(tracker.instances, 1)
      expectLargeVariant(array)

      let old2 = array.remove(at: 0)
      expectEqual(old2.payload, 20)
      expectEqual(array.count, 0)
      expectEqual(array.capacity, 2)
      expectTrue(array.isEmpty)
      expectEqual(tracker.instances, 1)
      _ = consume old2
      expectEqual(tracker.instances, 0)
      expectLargeVariant(array)
    }
  }
  
  func test_init_capacity() {
    do {
      let a = SmallArray<0, Int>(minimumCapacity: 0)
      expectEqual(a.capacity, 0)
      expectEqual(a.count, 0)
      expectEqual(a.freeCapacity, 0)
      expectTrue(a.isEmpty)
      expectSmallVariant(a)
    }

    do {
      let a = SmallArray<5, Int>(minimumCapacity: 0)
      expectEqual(a.capacity, 5)
      expectEqual(a.count, 0)
      expectEqual(a.freeCapacity, 5)
      expectTrue(a.isEmpty)
      expectSmallVariant(a)
    }
    
    do {
      let a = SmallArray<5, Int>(minimumCapacity: 10)
      expectEqual(a.capacity, 10)
      expectEqual(a.count, 0)
      expectEqual(a.freeCapacity, 10)
      expectTrue(a.isEmpty)
      expectLargeVariant(a)
    }
  }
  
  func test_init_repeating() {
    withLifetimeTracking { tracker in
      var c = 0
      let value = tracker.instance(for: 0)
      let a = SmallArray<0, _>(repeating: value, count: c)
      expectEqual(a.capacity, c)
      expectEqual(a.count, c)
      expectEqual(a.freeCapacity, 0)
      expectEqual(a.isEmpty, c == 0)
      expectSmallVariant(a)
      for i in 0 ..< c {
        expectIdentical(a[i], value)
      }
      
      c = 10
      let value2 = tracker.instance(for: 0)
      let a2 = SmallArray<10, _>(repeating: value2, count: c)
      expectEqual(a2.capacity, c)
      expectEqual(a2.count, c)
      expectEqual(a2.freeCapacity, 0)
      expectEqual(a2.isEmpty, c == 0)
      expectSmallVariant(a2)
      for i in 0 ..< c {
        expectIdentical(a2[i], value2)
      }
      
      c = 100
      let value3 = tracker.instance(for: 0)
      let a3 = SmallArray<100, _>(repeating: value3, count: c)
      expectEqual(a3.capacity, c)
      expectEqual(a3.count, c)
      expectEqual(a3.freeCapacity, 0)
      expectEqual(a3.isEmpty, c == 0)
      expectSmallVariant(a3)
      for i in 0 ..< c {
        expectIdentical(a3[i], value3)
      }
      
      c = 5
      let value4 = tracker.instance(for: 0)
      let a4 = SmallArray<1, _>(repeating: value4, count: c)
      expectEqual(a4.capacity, c)
      expectEqual(a4.count, c)
      expectEqual(a4.freeCapacity, 0)
      expectEqual(a4.isEmpty, c == 0)
      expectLargeVariant(a4)
      for i in 0 ..< c {
        expectIdentical(a4[i], value4)
      }
    }
  }
  
  func test_init_copying_Span() {
    do {
      withLifetimeTracking { tracker in
        let a: SmallArray<0, _> = tracker.smallArray()
        let b = UniqueArray(capacity: layout.capacity, copying: a.span)
        expectEqual(tracker.instances, layout.count)
        expectEqual(b.capacity, layout.capacity)
        expectEqual(b.count, layout.count)
        expectEqual(b.freeCapacity, layout.capacity - layout.count)
        expectEqual(b.isEmpty, layout.count == 0)
        for i in 0 ..< layout.count {
          expectEqual(b[i].payload, i)
        }
        expectUniqueArrayContents(
          b,
          equivalentTo: 0 ..< layout.count,
          by: { $0.payload == $1 },
          printer: { "\($0.payload)" })
      }
    }
    
    do {
      withLifetimeTracking { tracker in
        let a = tracker.uniqueArray(layout: layout)
        let b = UniqueArray(capacity: layout.capacity, copying: a.span)
        expectEqual(tracker.instances, layout.count)
        expectEqual(b.capacity, layout.capacity)
        expectEqual(b.count, layout.count)
        expectEqual(b.freeCapacity, layout.capacity - layout.count)
        expectEqual(b.isEmpty, layout.count == 0)
        for i in 0 ..< layout.count {
          expectEqual(b[i].payload, i)
        }
        expectUniqueArrayContents(
          b,
          equivalentTo: 0 ..< layout.count,
          by: { $0.payload == $1 },
          printer: { "\($0.payload)" })
      }
    }
    
    do {
      withLifetimeTracking { tracker in
        let a = tracker.uniqueArray(layout: layout)
        let b = UniqueArray(capacity: layout.capacity, copying: a.span)
        expectEqual(tracker.instances, layout.count)
        expectEqual(b.capacity, layout.capacity)
        expectEqual(b.count, layout.count)
        expectEqual(b.freeCapacity, layout.capacity - layout.count)
        expectEqual(b.isEmpty, layout.count == 0)
        for i in 0 ..< layout.count {
          expectEqual(b[i].payload, i)
        }
        expectUniqueArrayContents(
          b,
          equivalentTo: 0 ..< layout.count,
          by: { $0.payload == $1 },
          printer: { "\($0.payload)" })
      }
    }
  }
}

#endif
