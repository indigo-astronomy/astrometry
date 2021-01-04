//
//  SolverDelegate.swift
//  Astrometry
//
//  Created by Peter Polakovic on 18.12.15.
//  Copyright © 2015 CloudMakers, s. r. o. All rights reserved.
//

import Cocoa

class SolverDelegate: NSObject, NetServiceDelegate {

  @IBOutlet var window: NSWindow!
  @IBOutlet var logText: NSTextView!
  @IBOutlet var solveMenu: NSMenuItem!
  @IBOutlet var abortMenu: NSMenuItem!
  @IBOutlet var solveButton: NSButton!
  @IBOutlet var abortButton: NSButton!
  @IBOutlet var removeFilesButton: NSButton!
  @IBOutlet var writeWCSHeadersButton: NSButton!

  fileprivate var task: Process?
  fileprivate var status = "ready"
  fileprivate var message = ""
  
  fileprivate var raCenter: Double?
  fileprivate var decCenter: Double?
  fileprivate var orientation: Double?
  fileprivate var pixelScale: Double?
  
  func append(_ string: String, color: NSColor? = nil) {
    DispatchQueue.main.async {
      let stringToAppend = string + "\n"
      if let color = color {
        self.logText.textStorage!.append(NSAttributedString(string: stringToAppend, attributes: [NSAttributedString.Key.foregroundColor: color]))
      } else {
        self.logText.textStorage!.append(NSAttributedString(string: stringToAppend, attributes: [NSAttributedString.Key.foregroundColor: NSColor.controlTextColor]))
      }
      self.logText.scrollToEndOfDocument(self)
    }
  }
  
  func done(_ message: String? = nil) {
    DispatchQueue.main.async {
      if let message = message {
        self.append(message, color: GREEN)
        self.message = message.replacingOccurrences(of: "\n", with: "")
      }
      self.status = "done"
      self.solveMenu.isEnabled = true
      self.solveButton.isEnabled = true
      self.abortMenu.isEnabled = false
      self.abortButton.isEnabled = false
    }
  }
  
  func busy(_ message: String? = nil) {
    DispatchQueue.main.async {
      if let message = message {
        self.append(message, color: YELLOW)
        self.message = message.replacingOccurrences(of: "\n", with: "")
      }
      self.status = "busy"
      self.solveMenu.isEnabled = false
      self.solveButton.isEnabled = false
      self.abortMenu.isEnabled = true
      self.abortButton.isEnabled = true
    }
  }
  
  func failed(_ message: String? = nil) {
    DispatchQueue.main.async {
      if let message = message {
        self.append(message, color: RED)
        self.message = message.replacingOccurrences(of: "\n", with: "")
      }
      self.status = "failed"
      self.solveMenu.isEnabled = true
      self.solveButton.isEnabled = true
      self.abortMenu.isEnabled = false
      self.abortButton.isEnabled = false
    }
  }
  
  func execute(_ executable: String, arguments: [String], parse: Bool = false) throws {
    var cmd = "\n" + executable
    for arg in arguments {
      cmd += " " + arg
    }
    busy(cmd)
    task = Process()
    if let task = task {
      let pipe = Pipe()
      task.launchPath = Bundle.main.path(forAuxiliaryExecutable: executable)
      task.environment = [ "TMP": NSTemporaryDirectory()]
      task.arguments = arguments
      task.standardOutput = pipe
      task.standardError = pipe
      task.launch()
      if let output = StreamReader(fileHandle: pipe.fileHandleForReading) {
        while true {
          if let line = output.nextLine() {
            if !line.isEmpty {
              if parse {
                if line.hasPrefix("ra_center ") {
                  raCenter = Double(line.split(" ")[1])
                  self.append(line, color: GREEN)
                } else if line.hasPrefix("dec_center ") {
                  decCenter = Double(line.split(" ")[1])
                  self.append(line, color: GREEN)
                } else if line.hasPrefix("orientation ") {
                  orientation = Double(line.split(" ")[1])
                  self.append(line, color: GREEN)
                } else if line.hasPrefix("pixscale ") {
                  pixelScale = Double(line.split(" ")[1])
                  self.append(line, color: GREEN)
                } else {
                  self.append(line)
                }
              } else {
                self.append(line)
              }
            }
          } else {
            break
          }
        }
        usleep(100000)
        if task.terminationStatus == 0 {
          busy("\(executable) done")
        } else {
          if task.terminationStatus == 15 {
            failed("\(executable) aborted")
            throw NSError(domain: "aborted", code: 0, userInfo: nil)
          } else {
            failed("\(executable) terminated (status \(task.terminationStatus))")
            throw NSError(domain: "terminated", code: 0, userInfo: nil)
          }
        }
      } else {
        failed("\(executable) failed to start")
        throw NSError(domain: "failed", code: 0, userInfo: nil)
      }
    }
    task = nil
  }
  
  func addArgs(_ name: String, _ args: [String]) -> [String] {
    if let defaults = DEFAULTS.string(forKey: name) {
      var additional = defaults.split(" ")
      additional.append(contentsOf: args)
      return additional
    }
    return args;
  }
  
  func solvePath(_ path: String) {
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
      self.busy()
      let base = (path as NSString).deletingPathExtension
      let xy =  "\(base).xy"
      let wcs = "\(base).wcs"
      let wcs_fits = "\(base)_wcs.fits"
      var fits = path
      var rmFITS = false
      do {
        let start = Date().timeIntervalSince1970
        if !path.hasSuffix(".fit") && !path.hasSuffix(".fits") {
          fits = "\(base).fits"
          rmFITS = true
          self.busy("\nConverting \(path) to \(fits)...")
          if !Convert(path, fits) {
            self.failed("\nFailed to convert \(path) to FITS")
            return
          }
        }
        try self.execute("image2xy", arguments: [ "-O", "-o", xy, fits ])
        try self.execute("solve-field", arguments: self.addArgs("solve-field-args", [ "--overwrite", "--no-plots", "--no-remove-lines", "--no-verify-uniformize", "--sort-column", "FLUX", "--uniformize", "0", "--config", CONFIG, xy ]))
        if FileManager.default.fileExists(atPath: wcs) {
          if DEFAULTS.bool(forKey: "writeWCSHeaders") {
            try self.execute("new-wcs", arguments: [ "-v", "-d", "-i", fits, "-o", wcs_fits, "-w", wcs ])
          }
          self.raCenter = nil
          self.decCenter = nil
          self.orientation = nil
          self.pixelScale = nil
          try self.execute("wcsinfo", arguments: [ wcs ], parse: true)
          self.done("\nDone in \(round((Date().timeIntervalSince1970 - start) * 100) / 100) seconds")
        } else {
          self.failed("\nFailed to solve file")
        }
      } catch {
        self.failed("\nFailed to solve file")
      }
      let removeFiles = DispatchQueue.main.sync {
        return self.removeFilesButton.state == .on
      }
      if removeFiles {
        var files = [xy, wcs, "\(base).axy", "\(base).corr", "\(base).match", "\(base).rdls", "\(base).solved", "\(base)-indx.xyls" ]
        if rmFITS {
          files.append(fits)
        }
        for file in files {
          WORKSPACE.performFileOperation(NSWorkspace.FileOperationName.recycleOperation, source: "", destination: "", files: [file], tag: nil)
        }
      }
    }
  }
  
  @IBAction func solve(_ sender: AnyObject) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.prompt = "Select image file"
    panel.allowedFileTypes = [ "fit", "fits", "jpeg", "jpg", "png", "tif", "tiff", "raw", "nef", "cr2" ]
    panel.beginSheetModal(for: window, completionHandler: { result in
      if result.rawValue == NSFileHandlingPanelOKButton {
        if let url = panel.url {
          self.solvePath(url.path)
        }
      }
    })
  }

  @IBAction func abort(_ sender: AnyObject) {
    if let task = self.task {
      task.terminate()
    }
  }
  
  @IBAction func show(_ sender: AnyObject) {
    removeFilesButton.state = DEFAULTS.bool(forKey: "removeCreatedFiles") ? .on : .off
    writeWCSHeadersButton.state = DEFAULTS.bool(forKey: "writeWCSHeaders") ? .on : .off
    window.makeKeyAndOrderFront(self)
  }
  
  @IBAction func saveState(_ sender: AnyObject) {
    DEFAULTS.set(removeFilesButton.state == .on, forKey: "removeCreatedFiles")
    DEFAULTS.set(writeWCSHeadersButton.state == .on, forKey: "writeWCSHeaders")
  }
  
  func startServer() {
    let server = HttpServer()
    
    server.GET["/"] = { (request: HttpRequest) in
      return HttpResponse.ok(HttpResponseBody.html("<form action='/api/upload' method='post' enctype='multipart/form-data'>Submit FITS file: <input type='file' name='image'><input type='submit' value='Submit'></form>"))
    }
    
    server.POST["/api/upload"] = { (request: HttpRequest) in
      let data = request.parseMultiPartFormData()
      if data.count == 1 {
        if self.status != "busy" {
          let path = "\(NSTemporaryDirectory())image.fits"
          try? Data(bytes: UnsafePointer<UInt8>(data[0].body), count: data[0].body.count).write(to: URL(fileURLWithPath: path), options: [.atomic])
          self.append("\nFile uploaded to \(path) (\(data[0].body.count) bytes)", color: YELLOW)
          self.solvePath(path)
          return HttpResponse.ok(HttpResponseBody.json(["status":"success"] as AnyObject))
        } else {
          self.append("Solver busy", color: RED)
          return HttpResponse.ok(HttpResponseBody.json(["status":"error", "errormessage":"Solver busy"] as AnyObject))
        }
      }
      return HttpResponse.ok(HttpResponseBody.json(["status":"error", "errormessage":"Invalid request"] as AnyObject))
    }
    
    server.PUT["/api/upload"] = { (request: HttpRequest) in
      if self.status != "busy" {
        var fileName = "image.fits"
        if let contentDisposition = request.headers["content-disposition"] {
          let components = contentDisposition.components(separatedBy: "; ")
          for component in components {
            if component.hasPrefix("filename=") {
              fileName = component.components(separatedBy: "\"")[1]
            }
          }
        }
        let path = "\(NSTemporaryDirectory())\(fileName)"
        try? Data(bytes: UnsafePointer<UInt8>(request.body), count: request.body.count).write(to: URL(fileURLWithPath: path), options: [.atomic])
        self.busy("\nFile uploaded to \(path) (\(request.body.count) bytes)")
        self.solvePath(path)
        return HttpResponse.ok(HttpResponseBody.json(["status":"success"] as AnyObject))
      } else {
        self.append("Solver busy", color: RED)
        return HttpResponse.ok(HttpResponseBody.json(["status":"error", "errormessage":"Solver busy"] as AnyObject))
      }
    }
    
    server.GET["/api/status"] = { (request: HttpRequest) in
      var response: [String:AnyObject] = [ "status": self.status as AnyObject]
      var calibration: [String:AnyObject] = [:]
      if self.status == "ready" {
      } else if self.status == "done" {
        if let raCenter = self.raCenter {
          calibration["ra"] = raCenter as AnyObject?
        }
        if let decCenter = self.decCenter {
          calibration["dec"] = decCenter as AnyObject?
        }
        if let orientation = self.orientation {
          calibration["orientation"] = orientation as AnyObject?
        }
        if let pixelScale = self.pixelScale {
          calibration["pixscale"] = pixelScale as AnyObject?
        }
        response["calibration"] = calibration as AnyObject?
      } else {
        response["message"] = self.message as AnyObject?
      }
      return HttpResponse.ok(HttpResponseBody.json(response as AnyObject))
    }
    
    do {
      try server.start()
      server.publish("", type: "_astrometry._tcp", name: "Astrometry", delegate: self)
      try self.append("HTTP server started on port \(server.port())", color: GREEN)
    } catch {
      self.append("Can't start HTTP server", color: RED)
    }
  }
  
  func netServiceDidPublish(_ sender: NetService) {
    append("Bonjour service did publish", color: GREEN)
  }
  
  func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    append("Bonjour service did not publish", color: RED)
    append("\(errorDict)", color: RED)
  }
  
}

