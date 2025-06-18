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

#if swift(>=5.8)

@available(macOS 26, *)
extension BigString: TextOutputStream {
  public mutating func write(_ string: String) {
    append(contentsOf: string)
  }
}

@available(macOS 26, *)
extension BigString: TextOutputStreamable {
  public func write(to target: inout some TextOutputStream) {
    for chunk in _rope {
      let str = String(unsafeUninitializedCapacity: chunk.utf8Count) {
        $0.initialize(fromContentsOf: chunk._bytes)
      }
      
      str.write(to: &target)
    }
  }
}

#endif
