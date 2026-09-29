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
extension InlinedArray where Element: ~Copyable {
  @export(implementation)
  public consuming func consumeForEach<E>(
    _ body: (consuming Element) throws(E) -> ()
  ) throws(E) {
    for i in 0 ..< count {
      var ms = _storage.mutableSpan
      try ms.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) throws(E) -> () in
        let typedBuffer = buffer.assumingMemoryBound(to: Element.self)
        
        try body(typedBuffer.moveElement(from: i))
      }
    }
    
    discard self
  }
}
