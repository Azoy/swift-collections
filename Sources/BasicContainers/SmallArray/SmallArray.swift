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
public enum SmallArray<
  let count: Int, Element: ~Copyable, let bytes: Int
>: ~Copyable {
  // FIXME: Technically, `count` is never used, but in an ideal world
  //        `InlinedArray` uses it directly instead of the `bytes` parameter
  //        which is unnecessary.
  case small(InlinedArray<Element, bytes>)
  case large(UniqueArray<Element>)
}


