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

@available(macOS 9999, *)
extension BigString {
  internal final class _Chunk: ManagedBuffer<_Chunk.Counts, UInt8> {
    typealias Slice = (string: Substring, characters: Int, prefix: Int, suffix: Int)
    
    static func create() -> _Chunk {
      let chunk = create(minimumCapacity: 0) { _ in
        Counts()
      }
      
      return unsafeDowncast(chunk, to: _Chunk.self)
    }
    
    static func create(_ string: String, _ counts: Counts) -> _Chunk {
      let mb = create(minimumCapacity: Int(counts.utf8)) {
        $0.withUnsafeMutablePointerToElements {
          let buffer = UnsafeMutableBufferPointer(
            start: $0,
            count: Int(counts.utf8)
          )
          
          _ = buffer.initialize(from: string.utf8)
        }
        
        return counts
      }

      let chunk = unsafeDowncast(mb, to: _Chunk.self)
      chunk.invariantCheck()
      
      return chunk
    }

    static func create(_ string: Substring, _ counts: Counts) -> _Chunk {
      create(String(string), counts)
    }

    static func create(_ slice: Slice) -> _Chunk {
      let string = String(slice.string)
      let counts = Counts((string[...], slice.characters, slice.prefix, slice.suffix))
      return create(string, counts)
    }
  }
}

@available(macOS 9999, *)
extension BigString._Chunk {
  var startIndex: Index {
    Index(utf8Offset: 0).knownScalarAligned()
  }
  
  var endIndex: Index {
    Index(utf8Offset: Int(counts.utf8)).knownScalarAligned()
  }
  
  var counts: Counts {
    header
  }
  
  var _bytes: UnsafeBufferPointer<UInt8> {
    withUnsafeMutablePointerToElements {
      UnsafeBufferPointer(start: $0, count: Int(counts.utf8))
    }
  }
  
  var span: Span<UInt8> {
    @lifetime(borrow self)
    get {
      let span = Span(_unsafeElements: _bytes)
      return _overrideLifetime(span, borrowing: self)
    }
  }
  
  var utf8Span: UTF8Span {
    @lifetime(borrow self)
    get {
      return _overrideLifetime(UTF8Span(unchecked: span), borrowing: self)
    }
  }
  
  @lifetime(borrow self)
  func utf8Span(from i: Int, to j: Int? = nil) -> UTF8Span {
    guard j == nil else {
      let span = span._extracting(i..<j!)
      return _overrideLifetime(UTF8Span(unchecked: span), borrowing: self)
    }
    
    let span = span._extracting(i...)
    return _overrideLifetime(UTF8Span(unchecked: span), borrowing: self)
  }
}

@available(macOS 9999, *)
extension BigString._Chunk {
  @inline(__always)
  static var maxUTF8Count: Int { 255 }
  
  @inline(__always)
  static var minUTF8Count: Int { maxUTF8Count / 2 - maxSlicingError }
  
  @inline(__always)
  static var maxSlicingError: Int { 3 }
}

//@available(macOS 9999, *)
//extension BigString._Chunk {
//  @inline(__always)
//  func take() -> Self {
//    let r = self
//    self = Self()
//    return r
//  }
//
//  @inline(__always)
//  func modify<R>(
//    _ body: (inout Self) -> R
//  ) -> R {
//    body(&self)
//  }
//}

@available(macOS 9999, *)
extension BigString._Chunk {
  @inline(__always)
  var characterCount: Int { counts.characters }
  
  @inline(__always)
  var unicodeScalarCount: Int { Int(counts.unicodeScalars) }
  
  @inline(__always)
  var utf16Count: Int { Int(counts.utf16) }
  
  @inline(__always)
  var utf8Count: Int { Int(counts.utf8) }
  
  @inline(__always)
  var prefixCount: Int { counts.prefix }
  
  @inline(__always)
  var suffixCount: Int { counts.suffix }
  
  var firstScalar: Unicode.Scalar { unicodeScalars.first! }
  var lastScalar: Unicode.Scalar { unicodeScalars.last! }
}

@available(macOS 9999, *)
extension BigString._Chunk {
  var availableSpace: Int { Swift.max(0, Self.maxUTF8Count - utf8Count) }
}

@available(macOS 9999, *)
extension BigString._Chunk {
  func hasSpaceToMerge(_ other: some StringProtocol) -> Bool {
    utf8Count + other.utf8.count <= Self.maxUTF8Count
  }
  
  func hasSpaceToMerge(_ other: BigString._Chunk) -> Bool {
    utf8Count + other.utf8Count <= Self.maxUTF8Count
  }
}

#endif
