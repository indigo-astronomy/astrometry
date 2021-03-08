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
  fileprivate var parity: Double?
  
  func append(_ string: String, color: NSColor? = nil) {
    DispatchQueue.main.async { [self] in
      let stringToAppend = string + "\n"
      if let color = color {
        logText.textStorage!.append(NSAttributedString(string: stringToAppend, attributes: [NSAttributedString.Key.foregroundColor: color]))
      } else {
        logText.textStorage!.append(NSAttributedString(string: stringToAppend, attributes: [NSAttributedString.Key.foregroundColor: NSColor.controlTextColor]))
      }
      logText.scrollToEndOfDocument(self)
    }
  }
  
  func done(_ message: String? = nil) {
    DispatchQueue.main.async { [self] in
      if let message = message {
        append(message, color: GREEN)
        self.message = message.replacingOccurrences(of: "\n", with: "")
      }
      status = "done"
      solveMenu.isEnabled = true
      solveButton.isEnabled = true
      abortMenu.isEnabled = false
      abortButton.isEnabled = false
    }
  }
  
  func busy(_ message: String? = nil) {
    DispatchQueue.main.async { [self] in
      if let message = message {
        append(message, color: YELLOW)
        self.message = message.replacingOccurrences(of: "\n", with: "")
      }
      status = "busy"
      solveMenu.isEnabled = false
      solveButton.isEnabled = false
      abortMenu.isEnabled = true
      abortButton.isEnabled = true
    }
  }
  
  func failed(_ message: String? = nil) {
    DispatchQueue.main.async { [self] in
      if let message = message {
        append(message, color: RED)
        self.message = message.replacingOccurrences(of: "\n", with: "")
      }
      status = "failed"
      solveMenu.isEnabled = true
      solveButton.isEnabled = true
      abortMenu.isEnabled = false
      abortButton.isEnabled = false
    }
  }
  
  func execute(_ executable: String, arguments: [String], result: FileHandle? = nil) throws {
    var cmd =  "\n" + executable
    for arg in arguments {
      cmd += " " + arg
    }
    busy(cmd)
    task = Process()
    if let task = task {
      let pipe = Pipe()
      task.launchPath = Bundle.main.path(forAuxiliaryExecutable: executable)
      task.currentDirectoryPath = FOLDER.path
      task.environment = [ "TMP": NSTemporaryDirectory()]
      task.arguments = arguments
      task.standardOutput = pipe
      task.standardError = pipe
      task.launch()
      while true {
        if let line = pipe.fileHandleForReading.readLine() {
          if !line.isEmpty {
            if line.hasPrefix("ra_center ") {
              raCenter = Double(line.split(" ")[1])
              append(line, color: GREEN)
            } else if line.hasPrefix("dec_center ") {
              decCenter = Double(line.split(" ")[1])
              append(line, color: GREEN)
            } else if line.hasPrefix("orientation ") {
              orientation = Double(line.split(" ")[1])
              append(line, color: GREEN)
            } else if line.hasPrefix("pixscale ") {
              pixelScale = Double(line.split(" ")[1])
              append(line, color: GREEN)
            } else if line.hasPrefix("parity ") {
              parity = Double(line.split(" ")[1])
            } else {
              append(line)
            }
          }
          result?.writeLine(line)
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
    }
    task = nil
  }
  
  func solvePath(_ input: String, _ output: String?, _ image2xyArgs: [String]? = nil, _ solverArgs: [String]? = nil) {
    DispatchQueue.global(qos: .default).async { [self] in
      busy()
      do {
        var config = "cpulimit 300\nadd_path \(FOLDER.path)\n"
        for key in FILES.keys {
          if let files = FILES[key] {
            for file in files {
              if FILE_MANAGER.fileExists(atPath: FOLDER.appendingPathComponent(file).path) {
                config += "index \(file)\n"
              }
            }
          }
        }
        if let config = config.data(using: String.Encoding.ascii) {
          try config.write(to: CONFIG, options: [.atomic])
        }
      } catch {
        failed("\nFailed to create configuration file")
      }
      let base = input.hash
      let xy = "\(NSTemporaryDirectory())\(base).xy"
      let axy = "\(NSTemporaryDirectory())\(base).axy"
      let wcs = "\(NSTemporaryDirectory())\(base).wcs"
      var fits = input
      var rmFITS = false
      do {
        let start = Date().timeIntervalSince1970
        if !input.hasSuffix(".fit") && !input.hasSuffix(".fits") {
          fits = "\(NSTemporaryDirectory())\(base).fits"
          rmFITS = true
          busy("\nConverting \(input) to \(fits)...")
          if !Convert(input, fits) {
            failed("\nFailed to convert \(input) to FITS")
            return
          }
        }
        var args = [ "-O" ]
        if let additionalArgs = image2xyArgs {
          args.append(contentsOf: additionalArgs)
        }
        args.append(contentsOf: [ "-o", xy, fits ])
        try execute("image2xy", arguments: args)
        args = [ "--overwrite", "--no-plots", "--no-remove-lines", "--no-verify-uniformize", "--sort-column", "FLUX", "--uniformize", "0" ]
        if let additionalArgs = solverArgs {
          args.append(contentsOf: additionalArgs)
        }
        args.append(contentsOf: [ "--axy", axy, "--config", CONFIG.path, xy ])
        try execute("solve-field", arguments: args)
        if FileManager.default.fileExists(atPath: wcs) {
          if let output = output {
            try execute("new-wcs", arguments: [ "-d", "-i", fits, "-o", output, "-w", wcs ])
          }
          raCenter = nil
          decCenter = nil
          orientation = nil
          pixelScale = nil
          parity = nil
          try execute("wcsinfo", arguments: [ wcs ])
          done("\nDone in \(round((Date().timeIntervalSince1970 - start) * 100) / 100) seconds")
        } else {
          failed("\nFailed to solve file")
        }
      } catch {
        failed("\nFailed to solve file")
      }
      let removeFiles = DispatchQueue.main.sync {
        return removeFilesButton.state == .on
      }
      if removeFiles {
        var files = [xy, wcs, axy, "\(NSTemporaryDirectory())\(base).corr", "\(NSTemporaryDirectory())\(base).match", "\(NSTemporaryDirectory())\(base).rdls", "\(NSTemporaryDirectory())\(base).solved", "\(NSTemporaryDirectory())\(base)-indx.xyls" ]
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
    let openPanel = NSOpenPanel()
    openPanel.canChooseFiles = true
    openPanel.prompt = "Select image file"
    openPanel.allowedFileTypes = [ "fit", "fits", "jpeg", "jpg", "png", "tif", "tiff", "raw", "nef", "cr2" ]
    openPanel.beginSheetModal(for: window, completionHandler: { [self] result in
      if result.rawValue == NSFileHandlingPanelOKButton {
        if let openURL = openPanel.url {
          busy("\nProcessing manual request")
          if DEFAULTS.bool(forKey: "writeWCSHeaders") {
            let savePanel = NSSavePanel()
            savePanel.directoryURL = openPanel.directoryURL
            savePanel.nameFieldStringValue = openURL.deletingPathExtension().lastPathComponent + "_wcs"
            savePanel.allowedFileTypes = [ "fits" ]
            savePanel.prompt = "Select output file"
            savePanel.beginSheetModal(for: window, completionHandler: { result in
              if result.rawValue == NSFileHandlingPanelOKButton {
                if let saveURL = savePanel.url {
                  solvePath(openURL.path, saveURL.path)
                }
              }
            })
          } else {
            solvePath(openURL.path, nil)
          }
        }
      }
    })
  }

  @IBAction func abort(_ sender: AnyObject) {
    if let task = task {
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
    
    server.POST["/api/upload"] = { [self] (request: HttpRequest) in
      if status != "busy" {
        busy("\nProcessing HTTP request")
        let data = request.parseMultiPartFormData()
        if data.count == 1 {
          let path = "\(NSTemporaryDirectory())image.fits"
          try? Data(bytes: data[0].body, count: data[0].body.count).write(to: URL(fileURLWithPath: path), options: [.atomic])
          busy("\nFile uploaded to \(path) (\(data[0].body.count) bytes)")
          solvePath(path, nil)
          return HttpResponse.ok(HttpResponseBody.json(["status":"success"] as AnyObject))
        }
        return HttpResponse.ok(HttpResponseBody.json(["status":"error", "errormessage":"Invalid request"] as AnyObject))
      } else {
        append("Solver busy", color: RED)
        return HttpResponse.ok(HttpResponseBody.json(["status":"error", "errormessage":"Solver busy"] as AnyObject))
      }
    }
    
    server.PUT["/api/upload"] = { [self] (request: HttpRequest) in
      if status != "busy" {
        busy("\nProcessing HTTP request")
        var fileName = "image.fits"
        var image2xyArgs = [String]()
        var solverArgs = [String]()
        if let downsample = request.headers["downsample_factor"] {
          image2xyArgs = ["-d", downsample]
        }
        if let radius = request.headers["radius"], let ra = request.headers["ra_center"], let dec = request.headers["dec_center"] {
          solverArgs = ["--ra",  ra, "--dec", dec, "--radius", radius]
        }
        if let parity = request.headers["parity"] {
          solverArgs.append(contentsOf: ["--parity",  parity])
        }
        if let cpu = request.headers["cpulimit"] {
          solverArgs.append(contentsOf: ["--cpulimit",  cpu])
        }
        if let depth = request.headers["depth"] {
          solverArgs.append(contentsOf: ["--depth",  depth])
        }
        if let contentDisposition = request.headers["content-disposition"] {
          let components = contentDisposition.components(separatedBy: "; ")
          for component in components {
            if component.hasPrefix("filename=") {
              fileName = component.components(separatedBy: "\"")[1]
            }
          }
        }
        let path = "\(NSTemporaryDirectory())\(fileName)"
        try? Data(bytes: request.body, count: request.body.count).write(to: URL(fileURLWithPath: path), options: [.atomic])
        busy("\nFile uploaded to \(path) (\(request.body.count) bytes)")
        solvePath(path, nil, image2xyArgs, solverArgs)
        return HttpResponse.ok(HttpResponseBody.json(["status":"success"] as AnyObject))
      } else {
        append("Solver busy", color: RED)
        return HttpResponse.ok(HttpResponseBody.json(["status":"error", "errormessage":"Solver busy"] as AnyObject))
      }
    }
    
    server.GET["/api/status"] = { [self] (request: HttpRequest) in
      var response: [String:AnyObject] = [ "status": status as AnyObject]
      var calibration: [String:AnyObject] = [:]
      if status == "ready" {
      } else if status == "done" {
        if let raCenter = raCenter {
          calibration["ra"] = raCenter as AnyObject?
        }
        if let decCenter = decCenter {
          calibration["dec"] = decCenter as AnyObject?
        }
        if let orientation = orientation {
          calibration["orientation"] = orientation as AnyObject?
        }
        if let pixelScale = pixelScale {
          calibration["pixscale"] = pixelScale as AnyObject?
        }
        if let parity = parity {
          calibration["parity"] = parity as AnyObject?
        }
        response["calibration"] = calibration as AnyObject?
      } else {
        response["message"] = message as AnyObject?
      }
      return HttpResponse.ok(HttpResponseBody.json(response as AnyObject))
    }
    
    do {
      try server.start()
      server.publish("", type: "_astrometry._tcp", name: "Astrometry", delegate: self)
      try append("HTTP server started on port \(server.port())", color: GREEN)
    } catch {
      append("Can't start HTTP server", color: RED)
    }
    
    DispatchQueue.global(qos: .default).async { [self] in
      append("IPC listener started", color: GREEN)
      let requestURL = FOLDER.appendingPathComponent("request")
      let responseURL = FOLDER.appendingPathComponent("response")
      mkfifo(requestURL.path, 0o666)
      mkfifo(responseURL.path, 0o666)
      while true {
        if let requestHandle = try? FileHandle(forReadingFrom: requestURL), let responseHandle = try? FileHandle(forWritingTo: responseURL) {
          if status == "busy" {
            responseHandle.writeLine("message: Solver is busy")
            responseHandle.writeLine("<<<EOF>>>")
            responseHandle.closeFile()
            requestHandle.closeFile()
          } else {
            busy("\nProcessing IPC request")
            var args = [String]()
            while true {
              if let line = requestHandle.readLine() {
                if line == "<<<EOF>>>" {
                  let command = args.removeFirst()
                  let start = Date().timeIntervalSince1970
                  do {
                    try execute(command, arguments: args, result: responseHandle)
                    done("\nDone in \(round((Date().timeIntervalSince1970 - start) * 100) / 100) seconds")
                  } catch {
                    failed("Failed to execute \(command)")
                  }
                  responseHandle.writeLine("<<<EOF>>>")
                  responseHandle.closeFile()
                  requestHandle.closeFile()
                  break
                } else {
                  args.append(line)
                }
              } else {
                break
              }
            }
          }
        } else {
          break
        }
      }
      failed("Failed to create named pipe for interprocess communication")
    }
  }
  
  func netServiceDidPublish(_ sender: NetService) {
    append("Bonjour service started", color: GREEN)
  }
  
  func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    append("Bonjour service failed", color: RED)
    append("\(errorDict)", color: RED)
  }
  
}

