//
//  Handlers.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

open class HttpHandlers {
  
  fileprivate static let rangePrefix = "bytes="
  
  open class func directory(_ dir: String) -> ((HttpRequest) -> HttpResponse) {
    return { request in
      
      guard let localPath = request.params.first else {
        return HttpResponse.notFound
      }
      
      let filesPath = dir + "/" + localPath.1
      
      guard let fileBody = try? Data(contentsOf: URL(fileURLWithPath: filesPath)) else {
        return HttpResponse.notFound
      }
      
      if let rangeHeader = request.headers["range"] {
        
        guard rangeHeader.hasPrefix(HttpHandlers.rangePrefix) else {
          return HttpResponse.badRequest
        }
        
        #if os(Linux)
          let rangeString = rangeHeader.substringFromIndex(HttpHandlers.rangePrefix.characters.count)
        #else
          let rangeString = rangeHeader.substring(from: rangeHeader.characters.index(rangeHeader.startIndex, offsetBy: HttpHandlers.rangePrefix.characters.count))
        #endif
        let rangeStringExploded = rangeString.split("-")
        guard rangeStringExploded.count == 2 else {
          return HttpResponse.badRequest
        }
        
        let startStr = rangeStringExploded[0]
        let endStr   = rangeStringExploded[1]
        
        guard let start = Int(startStr), let end = Int(endStr) else {
          var array = [UInt8](repeating: 0, count: fileBody.count)
          (fileBody as NSData).getBytes(&array, length: fileBody.count)
          return HttpResponse.raw(200, "OK", nil, array)
        }
        
        guard end < fileBody.count else {
          return HttpResponse.raw(416, "Requested range not satisfiable", nil, nil)
        }
        
        let subData = fileBody.subdata(in: Range(start...end))
        
        let headers = [
          "Content-Range" : "bytes \(startStr)-\(endStr)/\(fileBody.count)"
        ]
        
        var array = [UInt8](repeating: 0, count: subData.count)
        (subData as NSData).getBytes(&array, length: subData.count)
        return HttpResponse.raw(206, "Partial Content", headers, array)
        
      }
      else {
        var array = [UInt8](repeating: 0, count: fileBody.count)
        (fileBody as NSData).getBytes(&array, length: fileBody.count)
        return HttpResponse.raw(200, "OK", nil, array)
      }
      
    }
  }
  
  open class func directoryBrowser(_ dir: String) -> ( (HttpRequest) -> HttpResponse ) {
    return { r in
      if let (_, value) = r.params.first {
        let filePath = dir + "/" + value
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: filePath, isDirectory: &isDir) {
          if isDir.boolValue {
            do {
              let files = try fileManager.contentsOfDirectory(atPath: filePath)
              var response = "<h3>\(filePath)</h3></br><table>"
              response += files.map({ "<tr><td><a href=\"\(r.url)/\($0)\">\($0)</a></td></tr>"}).joined(separator: "")
              response += "</table>"
              return HttpResponse.ok(.html(response))
            } catch {
              return HttpResponse.notFound
            }
          } else {
            if let fileBody = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
              var array = [UInt8](repeating: 0, count: fileBody.count)
              (fileBody as NSData).getBytes(&array, length: fileBody.count)
              return HttpResponse.raw(200, "OK", nil, array)
            }
          }
        }
      }
      return HttpResponse.notFound
    }
  }
}
