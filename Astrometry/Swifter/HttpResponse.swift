//
//  HttpResponse.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum SerializationError: Error {
  case invalidObject
  case notSupported
}

public enum HttpResponseBody {
  
  case json(AnyObject)
  case html(String)
  case text(String)
  case custom(Any, (Any) throws -> String)
  
  func data() -> [UInt8]? {
    do {
      switch self {
      case .json(let object):
        guard let obj = object as? AnyObject, JSONSerialization.isValidJSONObject(obj) else {
          throw SerializationError.invalidObject
        }
        let json = try JSONSerialization.data(withJSONObject: obj, options: JSONSerialization.WritingOptions.prettyPrinted)
        return Array(UnsafeBufferPointer(start: (json as NSData).bytes.bindMemory(to: UInt8.self, capacity: json.count), count: json.count))
      case .text(let body):
        let serialised = body
        return [UInt8](serialised.utf8)
      case .html(let body):
        let serialised = "<html><meta charset=\"UTF-8\"><body>\(body)</body></html>"
        return [UInt8](serialised.utf8)
      case .custom(let object, let closure):
        let serialised = try closure(object)
        return [UInt8](serialised.utf8)
      }
    } catch {
      return [UInt8]("Serialisation error: \(error)".utf8)
    }
  }
}

public enum HttpResponse {
  
  case ok(HttpResponseBody), created, accepted
  case movedPermanently(String)
  case badRequest, unauthorized, forbidden, notFound
  case internalServerError
  case raw(Int, String, [String:String]?, [UInt8]?)
  
  func statusCode() -> Int {
    switch self {
    case .ok(_)                   : return 200
    case .created                 : return 201
    case .accepted                : return 202
    case .movedPermanently        : return 301
    case .badRequest              : return 400
    case .unauthorized            : return 401
    case .forbidden               : return 403
    case .notFound                : return 404
    case .internalServerError     : return 500
    case .raw(let code, _ , _, _) : return code
    }
  }
  
  func reasonPhrase() -> String {
    switch self {
    case .ok(_)                    : return "OK"
    case .created                  : return "Created"
    case .accepted                 : return "Accepted"
    case .movedPermanently         : return "Moved Permanently"
    case .badRequest               : return "Bad Request"
    case .unauthorized             : return "Unauthorized"
    case .forbidden                : return "Forbidden"
    case .notFound                 : return "Not Found"
    case .internalServerError      : return "Internal Server Error"
    case .raw(_, let phrase, _, _) : return phrase
    }
  }
  
  func headers() -> [String: String] {
    var headers = ["Server" : "Swifter \(Constants.VERSION)"]
    switch self {
    case .ok(let body):
      switch body {
      case .json(_)   : headers["Content-Type"] = "application/json"
      case .html(_)   : headers["Content-Type"] = "text/html"
      default:break
      }
    case .movedPermanently(let location):
      headers["Location"] = location
    case .raw(_, _, let rawHeaders, _):
      if let rawHeaders = rawHeaders {
        for (k, v) in rawHeaders {
          headers.updateValue(v, forKey: k)
        }
      }
    default:break
    }
    return headers
  }
  
  func body() -> [UInt8]? {
    switch self {
    case .ok(let body)           : return body.data()
    case .raw(_, _, _, let data) : return data
    default                      : return nil
    }
  }
}

/**
 Makes it possible to compare handler responses with '==', but
	ignores any associated values. This should generally be what
	you want. E.g.:
	
 let resp = handler(updatedRequest)
 if resp == .NotFound {
 print("Client requested not found: \(request.url)")
 }
 */

func ==(inLeft: HttpResponse, inRight: HttpResponse) -> Bool {
  return inLeft.statusCode() == inRight.statusCode()
}

