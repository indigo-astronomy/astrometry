//
//  SolverDelegate.swift
//  Astrometry
//
//  Created by Peter Polakovic on 18.12.15.
//  Copyright © 2015 CloudMakers, s. r. o. All rights reserved.
//

import Cocoa

class SolverDelegate: NSObject, NSNetServiceDelegate {

  @IBOutlet var window: NSWindow!
  @IBOutlet var logText: NSTextView!
  @IBOutlet var solveMenu: NSMenuItem!
  @IBOutlet var abortMenu: NSMenuItem!
  @IBOutlet var solveButton: NSButton!
  @IBOutlet var abortButton: NSButton!
  @IBOutlet var removeFilesButton: NSButton!
  @IBOutlet var writeWCSHeadersButton: NSButton!

  private var task: NSTask?
  private var status = "ready"
  private var message = ""
  
  private var raCenter: Double?
  private var decCenter: Double?
  private var orientation: Double?
  private var pixelScale: Double?
  
  func append(string: String, color: NSColor? = nil) {
    dispatch_async(dispatch_get_main_queue()) {
      let stringToAppend = string + "\n"
      if let color = color {
        self.logText.textStorage!.appendAttributedString(NSAttributedString(string: stringToAppend, attributes: [NSForegroundColorAttributeName: color]))
      } else {
        self.logText.textStorage!.appendAttributedString(NSAttributedString(string: stringToAppend))
      }
      self.logText.scrollToEndOfDocument(self)
    }
  }
  
  func done(message: String? = nil) {
    dispatch_async(dispatch_get_main_queue()) {
      if let message = message {
        self.append(message, color: GREEN)
        self.message = message.stringByReplacingOccurrencesOfString("\n", withString: "")
      }
      self.status = "done"
      self.solveMenu.enabled = true
      self.solveButton.enabled = true
      self.abortMenu.enabled = false
      self.abortButton.enabled = false
    }
  }
  
  func busy(message: String? = nil) {
    dispatch_async(dispatch_get_main_queue()) {
      if let message = message {
        self.append(message, color: YELLOW)
        self.message = message.stringByReplacingOccurrencesOfString("\n", withString: "")
      }
      self.status = "busy"
      self.solveMenu.enabled = false
      self.solveButton.enabled = false
      self.abortMenu.enabled = true
      self.abortButton.enabled = true
    }
  }
  
  func failed(message: String? = nil) {
    dispatch_async(dispatch_get_main_queue()) {
      if let message = message {
        self.append(message, color: RED)
        self.message = message.stringByReplacingOccurrencesOfString("\n", withString: "")
      }
      self.status = "failed"
      self.solveMenu.enabled = true
      self.solveButton.enabled = true
      self.abortMenu.enabled = false
      self.abortButton.enabled = false
    }
  }
  
  func execute(executable: String, arguments: [String], parse: Bool = false) throws {
    var cmd = "\n" + executable
    for arg in arguments {
      cmd += " " + arg
    }
    busy(cmd)
    task = NSTask()
    if let task = self.task {
      let pipe = NSPipe()
      task.launchPath = NSBundle.mainBundle().pathForAuxiliaryExecutable(executable)
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
  
  func solvePath(path: String) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
      self.busy()
      let base = (path as NSString).stringByDeletingPathExtension
      let xy =  "\(base).xy"
      let wcs = "\(base).wcs"
      let wcs_fits = "\(base)_wcs.fits"
      do {
        try self.execute("image2xy", arguments: [ "-O", "-o", xy, path ])
        try self.execute("solve-field", arguments: [ "--overwrite", "--no-fits2fits", "--no-plots", "--no-remove-lines", "--no-verify-uniformize", "--sort-column", "FLUX", "--uniformize", "0", "--config", CONFIG, xy ])
        try self.execute("new-wcs", arguments: [ "-v", "-d", "-i", path, "-o", wcs_fits, "-w", wcs ])
        self.raCenter = nil
        self.decCenter = nil
        self.orientation = nil
        self.pixelScale = nil
        try self.execute("wcsinfo", arguments: [ wcs ], parse: true)
        self.done("\nDone")
      } catch {
      }
      if self.removeFilesButton.state == NSOnState {
        WORKSPACE.performFileOperation(NSWorkspaceRecycleOperation, source: "", destination: "", files: [xy, wcs, "\(base).axy", "\(base).corr", "\(base).match", "\(base).rdls", "\(base).solved", "\(base)-indx.xyls" ], tag: nil)
      }
    }
  }
  
  @IBAction func solve(sender: AnyObject) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.prompt = "Select FITS image file"
    panel.allowedFileTypes = [ "fit", "fits" ]
    panel.beginSheetModalForWindow(window, completionHandler: { result in
      if result == NSFileHandlingPanelOKButton {
        if let url = panel.URL, path = url.path {
          self.solvePath(path)
        }
      }
    })
  }

  @IBAction func abort(sender: AnyObject) {
    if let task = self.task {
      task.terminate()
    }
  }
  
  @IBAction func show(sender: AnyObject) {
    removeFilesButton.state = DEFAULTS.boolForKey("removeCreatedFiles") ? NSOnState : NSOffState
    writeWCSHeadersButton.state = DEFAULTS.boolForKey("writeWCSHeaders") ? NSOnState : NSOffState
    window.makeKeyAndOrderFront(self)
  }
  
  @IBAction func saveState(sender: AnyObject) {
    DEFAULTS.setBool(removeFilesButton.state == NSOnState, forKey: "removeCreatedFiles")
    DEFAULTS.setBool(writeWCSHeadersButton.state == NSOnState, forKey: "writeWCSHeaders")
  }
  
  func startServer() {
    let server = HttpServer()
    
    server.GET["/"] = { (request: HttpRequest) in
      return HttpResponse.OK(HttpResponseBody.Html("<form action='/api/upload' method='post' enctype='multipart/form-data'>Submit FITS file: <input type='file' name='image'><input type='submit' value='Submit'></form>"))
    }
    
    server.POST["/api/upload"] = { (request: HttpRequest) in
      let data = request.parseMultiPartFormData()
      if data.count == 1 {
        if self.status != "busy" {
          let path = "\(NSTemporaryDirectory())image.fits"
          NSData(bytes: data[0].body, length: data[0].body.count).writeToFile(path, atomically: true)
          self.append("\nFile uploaded to \(path) (\(data[0].body.count) bytes)", color: YELLOW)
          self.solvePath(path)
          return HttpResponse.OK(HttpResponseBody.Json(["status":"success"]))
        } else {
          self.append("Solver busy", color: RED)
          return HttpResponse.OK(HttpResponseBody.Json(["status":"error", "errormessage":"Solver busy"]))
        }
      }
      return HttpResponse.OK(HttpResponseBody.Json(["status":"error", "errormessage":"Invalid request"]))
    }
    
    server.PUT["/api/upload"] = { (request: HttpRequest) in
      if self.status != "busy" {
        let path = "\(NSTemporaryDirectory())image.fits"
        NSData(bytes: request.body, length: request.body.count).writeToFile(path, atomically: true)
        self.busy("\nFile uploaded to \(path) (\(request.body.count) bytes)")
        self.solvePath(path)
        return HttpResponse.OK(HttpResponseBody.Json(["status":"success"]))
      } else {
        self.append("Solver busy", color: RED)
        return HttpResponse.OK(HttpResponseBody.Json(["status":"error", "errormessage":"Solver busy"]))
      }
    }
    
    server.GET["/api/status"] = { (request: HttpRequest) in
      var response: [String:AnyObject] = [ "status": self.status]
      var calibration: [String:AnyObject] = [:]
      if self.status == "ready" {
      } else if self.status == "done" {
        if let raCenter = self.raCenter {
          calibration["ra"] = raCenter
        }
        if let decCenter = self.decCenter {
          calibration["dec"] = decCenter
        }
        if let orientation = self.orientation {
          calibration["orientation"] = orientation
        }
        if let pixelScale = self.pixelScale {
          calibration["pixscale"] = pixelScale
        }
        response["calibration"] = calibration
      } else {
        response["message"] = self.message
      }
      return HttpResponse.OK(HttpResponseBody.Json(response))
    }
    
    do {
      try server.start()
      server.publish("", type: "_astrometry._tcp", name: "Astrometry", delegate: self)
      self.append("HTTP server started on port \(server.port)", color: GREEN)
    } catch {
      self.append("Can't start HTTP server", color: RED)
    }
  }
  
  func netServiceDidPublish(sender: NSNetService) {
    append("Bonjour service did publish", color: GREEN)
  }
  
  func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
    append("Bonjour service did not publish", color: RED)
    append("\(errorDict)", color: RED)
  }
  
}

