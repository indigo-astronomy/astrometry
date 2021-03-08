//
//  FileHandle.swift
//  Astrometry
//
//  Created by Peter Polakovic on 04/03/2021.
//  Copyright © 2021 CloudMakers, s. r. o. All rights reserved.
//

import Foundation

private let delimiter = "\n".data(using: .ascii)!

extension FileHandle {  
  func writeLine(_ line: String) {
    if let data = line.data(using: .utf8) {
      write(data)
      write(delimiter)
      synchronizeFile()
    }
  }
  
  func readLine() -> String? {
    let buffer = NSMutableData()
    while true {
      let char = readData(ofLength: 1)
      if char.count == 0 {
        if buffer.count == 0 {
          return nil
        }
        return String(data: buffer as Data, encoding: .utf8)
      }
      if char.first == 10 {
        return String(data: buffer as Data, encoding: .utf8)
      }
      buffer.append(char)
    }
  }
}
