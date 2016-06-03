//
//  String+Linux.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

extension String {
  
  public func split(separator: Character) -> [String] {
    return self.characters.split { $0 == separator }.map(String.init)
  }
  
  public func replace(old: Character, new: Character) -> String {
    var buffer = [Character]()
    self.characters.forEach { buffer.append($0 == old ? new : $0) }
    return String(buffer)
  }
  
  public func trim() -> String {
    var scalars = self.unicodeScalars
    while let _ = unicodeScalarToUInt32Whitespace(scalars.first) { scalars.removeFirst() }
    while let _ = unicodeScalarToUInt32Whitespace(scalars.last) { scalars.removeLast() }
    return String(scalars)
  }
  
  public func removePercentEncoding() -> String {
    var scalars = self.unicodeScalars
    var output = ""
    var bytesBuffer = [UInt8]()
    while let scalar = scalars.popFirst() {
      if scalar == "%" {
        let first = scalars.popFirst()
        let secon = scalars.popFirst()
        if let first = unicodeScalarToUInt32Hex(first), secon = unicodeScalarToUInt32Hex(secon) {
          bytesBuffer.append(first*16+secon)
        } else {
          if !bytesBuffer.isEmpty {
            output.appendContentsOf(UInt8ArrayToUTF8String(bytesBuffer))
            bytesBuffer.removeAll()
          }
          if let first = first { output.append(Character(first)) }
          if let secon = secon { output.append(Character(secon)) }
        }
      } else {
        if !bytesBuffer.isEmpty {
          output.appendContentsOf(UInt8ArrayToUTF8String(bytesBuffer))
          bytesBuffer.removeAll()
        }
        output.append(Character(scalar))
      }
    }
    if !bytesBuffer.isEmpty {
      output.appendContentsOf(UInt8ArrayToUTF8String(bytesBuffer))
      bytesBuffer.removeAll()
    }
    return output
  }
  
  private func unicodeScalarToUInt32Whitespace(x: UnicodeScalar?) -> UInt8? {
    if let x = x {
      if x.value >= 9 && x.value <= 13 {
        return UInt8(x.value)
      }
      if x.value == 32 {
        return UInt8(x.value)
      }
    }
    return nil
  }
  
  private func unicodeScalarToUInt32Hex(x: UnicodeScalar?) -> UInt8? {
    if let x = x {
      if x.value >= 48 && x.value <= 57 {
        return UInt8(x.value) - 48
      }
      if x.value >= 97 && x.value <= 102 {
        return UInt8(x.value) - 87
      }
      if x.value >= 65 && x.value <= 70 {
        return UInt8(x.value) - 55
      }
    }
    return nil
  }
}

public func UInt8ArrayToUTF8String(array: [UInt8]) -> String {
  #if os(Linux)
    return String(data: NSData(bytes: array, length: array.count), encoding: NSUTF8StringEncoding)
  #else
    if let s = String(data: NSData(bytes: array, length: array.count), encoding: NSUTF8StringEncoding) {
      return s
    }
    return ""
  #endif
}
