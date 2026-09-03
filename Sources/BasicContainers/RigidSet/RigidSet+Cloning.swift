//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidSet {
  public func clone() -> Self {
    clone(capacity: count)
  }
  
  public func clone(capacity: Int) -> Self {
    precondition(capacity >= count, "RigidSet capacity overflow")
    
    guard _table.count > 0 else {
      return RigidSet(capacity: capacity)
    }
    
    let newScale = _HTable.minimumScale(forCapacity: capacity)
    let newTable = _HTable(_capacity: capacity, scale: newScale)
    
    var new = Self(_table: newTable)
    
    let source = self._members.unsafelyUnwrapped
    let target = new._members.unsafelyUnwrapped
    
    if _table.isSmall {
      new._table.copyItems_Small(from: _table) { src, dst in
        (target + dst.offset).initialize(to: (source + src.offset).pointee)
      }
      
      return new
    }
    
    let seed = self._seed
    var src = source
    new._table.copyItems_Large(
      from: self._table,
      selector: {
        src = source + $0.offset
        return src.pointee._rawHashValue(seed: seed)
      },
      hashGenerator: {
        target[$0.offset]._rawHashValue(seed: seed)
      },
      swapper: {
        swap(&src.pointee, &target[$0.offset])
      },
      finalizer: {
        (target + $0.offset).initialize(to: src.pointee)
      }
    )
    
    return new
  }
}

#endif
