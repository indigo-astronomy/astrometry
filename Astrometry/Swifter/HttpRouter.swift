//
//  HttpRouter.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

open class HttpRouter {
  
  fileprivate var handlers: [(String?, pattern: [String], (HttpRequest) -> HttpResponse)] = []
  
  open func routes() -> [(method: String?, path: String)] {
    return handlers.map { ($0.0, "/" + $0.pattern.joined(separator: "/")) }
  }
  
  open func register(_ method: String?, path: String, handler: @escaping (HttpRequest) -> HttpResponse) {
    handlers.append((method, path.split("/"), handler))
    handlers.sort { $0.0.pattern.count < $0.1.pattern.count }
  }
  
  open func unregister(_ method: String?, path: String) {
    let tokens = path.split("/")
    handlers = handlers.filter { (meth, pattern, _) -> Bool in
      return meth != method || pattern != tokens
    }
  }
  
  open func select(_ method: String?, url: String) -> ([String: String], (HttpRequest) -> HttpResponse)? {
    let urlTokens = url.split("/")
    for (meth, pattern, handler) in handlers {
      if meth == nil || meth! == method {
        if let params = matchParams(pattern, valueTokens: urlTokens) {
          return (params, handler)
        }
      }
    }
    return nil
  }
  
  open func matchParams(_ patternTokens: [String], valueTokens: [String]) -> [String: String]? {
    var params = [String: String]()
    for index in 0..<valueTokens.count {
      if index >= patternTokens.count {
        return nil
      }
      let patternToken = patternTokens[index]
      let valueToken = valueTokens[index]
      if patternToken.isEmpty {
        if patternToken != valueToken {
          return nil
        }
      }
      if patternToken.characters.first == ":" {
        #if os(Linux)
          params[patternToken.substringFromIndex(1)] = valueToken
        #else
          params[patternToken.substring(from: patternToken.characters.index(after: patternToken.characters.startIndex))] = valueToken
        #endif
      } else {
        if patternToken != valueToken {
          return nil
        }
      }
    }
    return params
  }
}
