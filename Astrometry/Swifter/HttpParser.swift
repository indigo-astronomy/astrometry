//
//  HttpParser.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Foundation
#endif


enum HttpParserError: Error {
  case readBodyFailed(String)
  case invalidStatusLine(String)
}

class HttpParser {
  
  func readHttpRequest(_ socket: Socket) throws -> HttpRequest {
    let statusLine = try socket.readLine()
    let statusLineTokens = statusLine.split(" ")
    //print(statusLineTokens)
    if statusLineTokens.count < 3 {
      throw HttpParserError.invalidStatusLine(statusLine)
    }
    var request = HttpRequest()
    request.method = statusLineTokens[0]
    request.url = statusLineTokens[1]
    request.queryParams = extractUrlParams(request.url)
    request.headers = try readHeaders(socket)
    if let contentLength = request.headers["content-length"], let contentLengthValue = Int(contentLength) {
      request.body = try readBody(socket, size: contentLengthValue)
    }
    return request
  }
  
  fileprivate func extractUrlParams(_ url: String) -> [(String, String)] {
    guard let query = url.split("?").last else {
      return []
    }
    return query.split("&").map { (param: String) -> (String, String) in
      let tokens = param.split("=")
      guard let name = tokens.first, let value = tokens.last else {
        return ("", "")
      }
      return (name.removePercentEncoding(), value.removePercentEncoding())
    }
  }
  
  fileprivate func readBody(_ socket: Socket, size: Int) throws -> [UInt8] {
    var body = [UInt8]()
    var counter = 0
    while counter < size {
      body.append(try socket.read())
      counter += 1
    }
    return body
  }
  
  fileprivate func readHeaders(_ socket: Socket) throws -> [String: String] {
    var requestHeaders = [String: String]()
    repeat {
      let headerLine = try socket.readLine()
      if headerLine.isEmpty {
        return requestHeaders
      }
      let headerTokens = headerLine.split(":")
      if let name = headerTokens.first, headerTokens.count >= 2 {
        let value = headerTokens.dropFirst().joined(separator: ":")
        requestHeaders[name.lowercased()] = value.trim()
      }
    } while true
  }
  
  func supportsKeepAlive(_ headers: [String: String]) -> Bool {
    if let value = headers["connection"] {
      return "keep-alive" == value.trim()
    }
    return false
  }
}
