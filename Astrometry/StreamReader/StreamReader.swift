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
  
  var fileHandle : NSFileHandle!
  let buffer : NSMutableData!
  let delimData : NSData!
  var atEof : Bool = false
  
  init?(fileHandle : NSFileHandle, delimiter: String = "\n") {
    self.chunkSize = 64
    self.encoding = NSUTF8StringEncoding
    
    if let delimData = "\n".dataUsingEncoding(encoding), buffer = NSMutableData(capacity: chunkSize) {
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
    var range = buffer.rangeOfData(delimData, options: [], range: NSMakeRange(0, buffer.length))
    while range.location == NSNotFound {
      let tmpData = fileHandle.readDataOfLength(chunkSize)
      if tmpData.length == 0 {
        atEof = true
        if buffer.length > 0 {
          let line = NSString(data: buffer, encoding: encoding)
          buffer.length = 0
          return line as String?
        }
        return nil
      }
      buffer.appendData(tmpData)
      range = buffer.rangeOfData(delimData, options: [], range: NSMakeRange(0, buffer.length))
    }
    let line = NSString(data: buffer.subdataWithRange(NSMakeRange(0, range.location)), encoding: encoding)
    buffer.replaceBytesInRange(NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)
    return line as String?
  }
  
  func close() -> Void {
    fileHandle?.closeFile()
    fileHandle = nil
  }
}