//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public protocol Container<Element>: BorrowingSequence, ConsumingSequence, ~Copyable {
  associatedtype Element: ~Copyable & ~Escapable
  associatedtype Index

  var count: Int { get }

  var startIndex: Index { get }
  var endIndex: Index { get }
  func index(after index: Index) -> Index
  func index(_ index: Index, offsetBy delta: Int) -> Index
}

public protocol ConsumingSequence<ConsumingElement>: ~Copyable {
  associatedtype ConsumingElement: ~Copyable
  associatedtype ConsumingIterator: Iterator<ConsumingElement> & ~Copyable

  consuming func startConsumingIteration() -> ConsumingIterator

  @available(SwiftStdlib 5.0, *)
  @_lifetime(target: copy target)
  mutating func generate(into target: inout OutputSpan<ConsumingElement>) -> Bool

  // Other things like 'estimatedCount', 'isEmpty', etc.
}

extension ConsumingSequence where Self: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @_lifetime(target: copy target)
  public consuming func generate(
    into target: inout OutputSpan<ConsumingElement>
  ) -> Bool {
    var iter = startConsumingIteration()

    while let e = iter.next() {
      target.append(e)
    }

    return true
  }
}

public protocol BorrowingSequence<BorrowingElement>: ~Copyable, ~Escapable {
  associatedtype BorrowingElement: ~Copyable & ~Escapable
  associatedtype BorrowingIterator: Iterator<BorrowingElement> & ~Copyable & ~Escapable

  @_lifetime(borrow self)
  borrowing func startBorrowingIteration() -> BorrowingIterator

  // Other things like 'estimatedCount', 'isEmpty', etc.
}

public protocol MutatingSequence<MutatingElement>: BorrowingSequence, ~Copyable, ~Escapable {
  associatedtype MutatingElement: ~Copyable & ~Escapable
  associatedtype MutatingIterator: Iterator<MutatingElement> & ~Copyable & ~Escapable

  @_lifetime(&self)
  mutating func startMutatingIteration() -> MutatingIterator

  // Other things like 'estimatedCount', 'isEmpty', etc.
}

@frozen
public enum EstimatedCount {
  case infinite
  case exactly(Int)
  case unknown
 }

public protocol Iterator<SingleElement>: ~Copyable, ~Escapable {
  // FIXME: Naming of this thing
  associatedtype SingleElement: ~Copyable & ~Escapable

  // FIXME: Perhaps this should conform to some protocol to enforce bulkness?
  // It would also allow us to have some function that would take a single
  // element and convert into the bulk version giving us the opportunity to
  // have a default impleemntation of the 'bulkNext'.
  // associatedtype BulkElement: ~Copyable & ~Escapable

  var isEmpty: Bool { get }

  var estimatedCount: EstimatedCount { get }

  @_lifetime(copy self)
  mutating func next() -> SingleElement?

  // @_lifetime(copy self)
  // mutating func bulkNext(maximumCount: Int) -> BulkElement

  // @_lifetime(target: copy target)
  // mutating func generate(into target: inout OutputSpan<SingleElement>)
}

extension Iterator where Self: ~Copyable & ~Escapable {
  @_alwaysEmitIntoClient
  public var underestimatedCount: Int {
    switch estimatedCount {
    case .infinite:
      Int.max
    case .exactly(let c):
      c
    case .unknown:
      0
    }
  }
}

// FIXME: Remove single element escapable conformance
extension Iterator where Self: ~Copyable & ~Escapable, SingleElement: Escapable {
  @available(SwiftStdlib 5.0, *)
  @_lifetime(target: copy target)
  public mutating func generate(into target: inout OutputSpan<SingleElement>) {
    while let e = next() {
      target.append(e)
    }
  }
}
