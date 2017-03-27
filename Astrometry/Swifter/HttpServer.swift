//
//  HttpServer2.swift
//  Swifter
//
//  Created by Damian Kolakowski on 17/12/15.
//  Copyright © 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

open class HttpServer: HttpServerIO {
  
  fileprivate let router = HttpRouter()
  
  open var routes: [(method: String?, path: String)] {
    return router.routes()
  }
  
  open subscript(path: String) -> ((HttpRequest) -> HttpResponse)? {
    set {
      if let handler = newValue {
        self.router.register(nil, path: path, handler: handler)
      }
      else {
        self.router.unregister(nil, path: path)
      }
    }
    get { return nil }
  }
  
  open lazy var DELETE : Route = self.lazyBuild("DELETE")
  open lazy var UPDATE : Route = self.lazyBuild("UPDATE")
  open lazy var HEAD   : Route = self.lazyBuild("HEAD")
  open lazy var POST   : Route = self.lazyBuild("POST")
  open lazy var GET    : Route = self.lazyBuild("GET")
  open lazy var PUT    : Route = self.lazyBuild("PUT")
  
  public struct Route {
    public let method: String
    public let server: HttpServer
    public subscript(path: String) -> ((HttpRequest) -> HttpResponse)? {
      set {
        if let handler = newValue {
          server.router.register(method, path: path, handler: handler)
        } else {
          server.router.unregister(method, path: path)
        }
      }
      get { return nil }
    }
  }
  
  fileprivate func lazyBuild(_ method: String) -> Route {
    return Route(method: method, server: self)
  }
  
  override open func select(_ method: String, url: String) -> ([String : String], (HttpRequest) -> HttpResponse) {
    if let handler = router.select(method, url: url) {
      return handler
    }
    return super.select(method, url: url)
  }
}
