//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension FixedWidthInteger {
  static var range: ClosedRange<Self> {
    Self.min ... Self.max
  }
}

extension ClosedRange where Bound: BinaryInteger {
  @inline(__always)
  func contains<Other: BinaryInteger>(_ other: Other) -> Bool {
    other >= lowerBound && other <= upperBound
  }
}
