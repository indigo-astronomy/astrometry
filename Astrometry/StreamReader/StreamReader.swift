//
//  StreamReader.swift
//  StreamReader
//
//  Created by shim on 2014-11-15.
//  Copyright (c) 2014 Bupkis. All rights reserved.
//

import Cocoa

class StreamReader  {
  
  let encoding : UInt
  let chunkSize : Int
  
  var fileHandle : FileHandle!
  let buffer : NSMutableData!
  let delimData : Data!
  var atEof : Bool = false
  
  init?(fileHandle : FileHandle, delimiter: String = "\n") {
    self.chunkSize = 64
    self.encoding = String.Encoding.utf8.rawValue
    
    if let delimData = "\n".data(using: String.Encoding(rawValue: encoding)), let buffer = NSMutableData(capacity: chunkSize) {
      self.fileHandle = fileHandle
      self.delimData = delimData
      self.buffer = buffer
    } else {
      self.fileHandle = nil
      self.delimData = nil
      self.buffer = nil
      return nil
    }
  }
  
  deinit {
    self.close()
  }
  
  func nextLine() -> String? {
    precondition(fileHandle != nil, "Attempt to read from closed file")
    if atEof {
      return nil
    }
    var range = buffer.range(of: delimData, options: [], in: NSMakeRange(0, buffer.length))
    while range.location == NSNotFound {
      let tmpData = fileHandle.readData(ofLength: chunkSize)
      if tmpData.count == 0 {
        atEof = true
        if buffer.length > 0 {
          let line = NSString(data: buffer as Data, encoding: encoding)
          buffer.length = 0
          return line as String?
        }
        return nil
      }
      buffer.append(tmpData)
      range = buffer.range(of: delimData, options: [], in: NSMakeRange(0, buffer.length))
    }
    let line = NSString(data: buffer.subdata(with: NSMakeRange(0, range.location)), encoding: encoding)
    buffer.replaceBytes(in: NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)
    return line as String?
  }
  
  func close() -> Void {
    fileHandle?.closeFile()
    fileHandle = nil
  }
}
