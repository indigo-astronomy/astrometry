//
//  HttpRequest.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public struct HttpRequest {
  
  public var url: String = ""
  public var queryParams: [(String, String)] = []
  public var method: String = ""
  public var headers: [String: String] = [:]
  public var body: [UInt8] = []
  public var address: String? = ""
  public var params: [String: String] = [:]
  
  public func parseUrlencodedForm() -> [(String, String)] {
    guard let contentTypeHeader = headers["content-type"] else {
      return []
    }
    let contentTypeHeaderTokens = contentTypeHeader.split(";").map { $0.trim() }
    guard let contentType = contentTypeHeaderTokens.first where contentType == "application/x-www-form-urlencoded" else {
      return []
    }
    return UInt8ArrayToUTF8String(body).split("&").map { (param: String) -> (String, String) in
      let tokens = param.split("=")
      if let name = tokens.first, value = tokens.last where tokens.count == 2 {
        return (name.replace("+", new: " ").removePercentEncoding(),
          value.replace("+", new: " ").removePercentEncoding())
      }
      return ("","")
    }
  }
  
  public struct MultiPart {
    public let headers: [String: String]
    public let body: [UInt8]
  }
  
  public func parseMultiPartFormData() -> [MultiPart] {
    guard let contentTypeHeader = headers["content-type"] else {
      return []
    }
    let contentTypeHeaderTokens = contentTypeHeader.split(";").map { $0.trim() }
    guard let contentType = contentTypeHeaderTokens.first where contentType == "multipart/form-data" else {
      return []
    }
    var boundary: String? = nil
    contentTypeHeaderTokens.forEach({
      let tokens = $0.split("=")
      if let key = tokens.first where key == "boundary" && tokens.count == 2 {
        boundary = tokens.last
      }
    })
    if let boundary = boundary where boundary.utf8.count > 0 {
      return parseMultiPartFormData(body, boundary: "--\(boundary)")
    }
    return []
  }
  
  private func parseMultiPartFormData(data: [UInt8], boundary: String) -> [MultiPart] {
    var generator = data.generate()
    var result = [MultiPart]()
    while let part = nextMultiPart(&generator, boundary: boundary, isFirst: result.isEmpty) {
      result.append(part)
    }
    return result
  }
  
  private func nextMultiPart(inout generator: IndexingGenerator<[UInt8]>, boundary: String, isFirst: Bool) -> MultiPart? {
    if isFirst {
      guard nextMultiPartLine(&generator) == boundary else {
        return nil
      }
    } else {
      nextMultiPartLine(&generator)
    }
    var headers = [String: String]()
    while let line = nextMultiPartLine(&generator) where !line.isEmpty {
      let tokens = line.split(":")
      if let name = tokens.first, value = tokens.last where tokens.count == 2 {
        headers[name.lowercaseString] = value.trim()
      }
    }
    guard let body = nextMultiPartBody(&generator, boundary: boundary) else {
      return nil
    }
    return MultiPart(headers: headers, body: body)
  }
  
  private func nextMultiPartLine(inout generator: IndexingGenerator<[UInt8]>) -> String? {
    var result = String()
    while let value = generator.next() {
      if value > Constants.CR {
        result.append(Character(UnicodeScalar(value)))
      }
      if value == Constants.NL {
        break
      }
    }
    return result
  }
  
  private func nextMultiPartBody(inout generator: IndexingGenerator<[UInt8]>, boundary: String) -> [UInt8]? {
    var body = [UInt8]()
    let boundaryArray = [UInt8](boundary.utf8)
    var matchOffset = 0;
    while let x = generator.next() {
      matchOffset = ( x == boundaryArray[matchOffset] ? matchOffset + 1 : 0 )
      body.append(x)
      if matchOffset == boundaryArray.count {
        body.removeRange(Range<Int>(start: body.count-matchOffset, end: body.count))
        if body.last == Constants.NL {
          body.removeLast()
          if body.last == Constants.CR {
            body.removeLast()
          }
        }
        return body
      }
    }
    return nil
  }
}
