//
//  DemoServer.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public func demoServer(_ publicDir: String?) -> HttpServer {
  let server = HttpServer()
  
  if let publicDir = publicDir {
    server["/resources/:file"] = HttpHandlers.directory(publicDir)
  }
  
  server["/files/:path"] = HttpHandlers.directoryBrowser("~/")
  
  server["/"] = { r in
    var listPage = "Available services:<br><ul>"
    for (method, path) in server.routes {
      listPage += "<li><a href=\"\(path)\">\(method): \(path)</a></li>"
    }
    listPage += "</ul>"
    return .ok(.html(listPage))
  }
  
  server["/magic"] = { .ok(.html("You asked for " + $0.url)) }
  
  server["/test/:param1/:param2"] = { r in
    var headersInfo = ""
    for (name, value) in r.headers {
      headersInfo += "\(name) : \(value)<br>"
    }
    var queryParamsInfo = ""
    for (name, value) in r.queryParams {
      queryParamsInfo += "\(name) : \(value)<br>"
    }
    var pathParamsInfo = ""
    for token in r.params {
      pathParamsInfo += "\(token.0) : \(token.1)<br>"
    }
    return .ok(.html("<h3>Address: \(r.address)</h3><h3>Url:</h3> \(r.url)<h3>Method: \(r.method)</h3><h3>Headers:</h3>\(headersInfo)<h3>Query:</h3>\(queryParamsInfo)<h3>Path params:</h3>\(pathParamsInfo)"))
  }
  
  server.GET["/upload"] = { r in
    if let rootDir = publicDir, let html = try? Data(contentsOf: URL(fileURLWithPath: "\(rootDir)/file.html")) {
      var array = [UInt8](repeating: 0, count: html.count)
      (html as NSData).getBytes(&array, length: html.count)
      return HttpResponse.raw(200, "OK", nil, array)
    }
    
    return .notFound
  }
  
  server.POST["/upload"] = { r in
    let formFields = r.parseMultiPartFormData()
    return HttpResponse.ok(.html(formFields.map({ UInt8ArrayToUTF8String($0.body) }).joined(separator: "<br>")))
  }
  
  server.GET["/login"] = { r in
    if let rootDir = publicDir, let html = try? Data(contentsOf: URL(fileURLWithPath: "\(rootDir)/login.html")) {
      var array = [UInt8](repeating: 0, count: html.count)
      (html as NSData).getBytes(&array, length: html.count)
      return HttpResponse.raw(200, "OK", nil, array)
    }
    
    return .notFound
  }
  
  server.POST["/login"] = { r in
    let formFields = r.parseUrlencodedForm()
    return HttpResponse.ok(.html(formFields.map({ "\($0.0) = \($0.1)" }).joined(separator: "<br>")))
  }
  
  server["/demo"] = { r in
    return .ok(.html("<center><h2>Hello Swift</h2><img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br></center>"))
  }
  
  server["/raw"] = { request in
    return HttpResponse.raw(200, "OK", ["XXX-Custom-Header": "value"], [UInt8]("Sample Response".utf8))
  }
  
  server["/json"] = { request in
    let jsonObject: NSDictionary = [NSString(string: "foo"): NSNumber(value: 3 as Int32), NSString(string: "bar"): NSString(string: "baz")]
    return .ok(.json(jsonObject))
  }
  
  server["/redirect"] = { request in
    return .movedPermanently("http://www.google.com")
  }
  
  server["/long"] = { request in
    var longResponse = ""
    for k in 0..<1000 { longResponse += "(\(k)),->" }
    return .ok(.html(longResponse))
  }
  
  return server
}
