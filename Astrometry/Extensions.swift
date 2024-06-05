//
//  Extensions.swift
//  Astrometry
//
//  Created by Polakovic Peter on 05/06/2024.
//  Copyright © 2024 CloudMakers, s. r. o. All rights reserved.
//

import Foundation

extension String {
  var doubleValue: Double {
    get {
      return (self as NSString).doubleValue
    }
  }
  
  var integerValue: Int {
    get {
      return (self as NSString).integerValue
    }
  }
  
  func trim() -> String {
    return self.trimmingCharacters(in: .whitespaces)
  }
  
  static func * (left: String, right: Int) -> String {
    var result = ""
    if right > 0 {
      for _ in 0..<right {
        result += left
      }
    }
    return result
  }

  subscript(_ range: CountableRange<Int>) -> String {
    let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
    let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
    return String(self[idx1..<idx2])
  }
  
  subscript(_ range: CountableClosedRange<Int>) -> String {
    let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
    let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
    return String(self[idx1...idx2])
  }
  
  subscript(_ range: PartialRangeFrom<Int>) -> String {
    let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
    return String(self[idx1...])
  }
  
  subscript(_ range: PartialRangeUpTo<Int>) -> String {
    let idx2 = index(startIndex, offsetBy: max(0, range.upperBound))
    return String(self[..<idx2])
  }
  
  subscript(_ range: PartialRangeThrough<Int>) -> String {
    let idx2 = index(startIndex, offsetBy: max(0, range.upperBound))
    return String(self[...idx2])
  }
}
