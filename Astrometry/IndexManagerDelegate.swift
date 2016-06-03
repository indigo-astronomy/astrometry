//
//  IndexManagerDelegate.swift
//  Astrometry
//
//  Created by Peter Polakovic on 18/12/15.
//  Copyright © 2015 CloudMakers, s. r. o. All rights reserved.
//

import Cocoa

class IndexManagerDelegate: NSObject, NSURLDownloadDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var series4200: NSView!
  @IBOutlet weak var series4100: NSView!
  @IBOutlet weak var goButton: NSButton!
  @IBOutlet weak var abortButton: NSButton!
  @IBOutlet weak var queueIndicator: NSLevelIndicator!
  @IBOutlet weak var fileIndicator: NSLevelIndicator!
  @IBOutlet weak var statusText: NSTextField!
  
  var queue: [String] = []
  var currentLength = 0
  var download: NSURLDownload?
  
  func validate(checkbox: NSButton) {
    if let files = FILES[checkbox.title] {
      var count = 0
      for file in files {
        let path = "\(FOLDER)/\(file)"
        if FILE_NAMANGER.fileExistsAtPath(path) {
          count++
        }
      }
      if count == 0 {
        checkbox.state = 0
      } else if count == files.count {
        checkbox.state = 1
      } else {
        checkbox.state = -1
      }
    }
  }

  func downloadDidBegin(download: NSURLDownload) {
    currentLength = 0
    dispatch_async(dispatch_get_main_queue()) {
      self.fileIndicator.integerValue = 0
    }
  }
  
  func download(download: NSURLDownload, didReceiveResponse response: NSURLResponse) {
    dispatch_async(dispatch_get_main_queue()) {
      self.statusText.stringValue += " (\(response.expectedContentLength) bytes)"
      self.fileIndicator.maxValue = Double(response.expectedContentLength)
    }
  }
  
  func download(download: NSURLDownload, didReceiveDataOfLength length: Int) {
    currentLength += length
    dispatch_async(dispatch_get_main_queue()) {
      self.fileIndicator.integerValue = self.currentLength
    }
  }
  
  func downloadDidFinish(download: NSURLDownload) {
    dispatch_async(dispatch_get_main_queue()) {
      self.downloadQueue()
    }
  }
  
  func download(download: NSURLDownload, didFailWithError error: NSError) {
    NSLog("file failed \(error)")
    dispatch_async(dispatch_get_main_queue()) {
      self.statusText.stringValue += " - failed"
      self.goButton.enabled = true
      self.abortButton.enabled = false
    }
  }
  
  func downloadQueue() {
    if let file = queue.first {
      queueIndicator.integerValue++
      statusText.stringValue = "Downloading \(file)"
      var url: NSURL?
      queue.removeFirst()
      if file.hasPrefix("index-41") {
        url = NSURL(string: "http://broiler.astrometry.net/~dstn/4100/\(file)")
      } else if file.hasPrefix("index-42") {
        url = NSURL(string: "http://broiler.astrometry.net/~dstn/4200/\(file)")
      }
      if let url = url {
        download = NSURLDownload(request: NSURLRequest(URL: url), delegate: self)
        if let download = download {
          download.deletesFileUponFailure = true
          download.setDestination("\(FOLDER)/\(file)", allowOverwrite: true)
        } else {
          statusText.stringValue = "Failed to download \(file)"
          goButton.enabled = true
          abortButton.enabled = false
        }
      }
    } else {
      download = nil
      statusText.stringValue = "Done"
      goButton.enabled = true
      abortButton.enabled = false
    }
  }
  
  func process(checkbox: NSButton) {
    let title = checkbox.title
    if let files = FILES[title] {
      for file in files {
        let path = "\(FOLDER)/\(file)"
        if FILE_NAMANGER.fileExistsAtPath(path) {
          if checkbox.state == 0 {
            WORKSPACE.performFileOperation(NSWorkspaceRecycleOperation, source: FOLDER, destination: "", files: [file], tag: nil)
            self.statusText.stringValue = "Removed \(file)"
          }
        } else {
          if checkbox.state == 1 {
            queue.append(file)
          }
        }
      }
    }
  }
  
  @IBAction func skip2(sender: AnyObject) {
    let button = sender as! NSButton
    if button.state == -1 {
      button.state = 1
    }
  }

  @IBAction func readme(sender: AnyObject) {
    NSWorkspace.sharedWorkspace().openURL(NSURL(string: "http://astrometry.net/doc/readme.html")!)
  }

  @IBAction func abort(sender: AnyObject) {
    queue.removeAll()
    if let download = self.download {
      download.cancel()
    }
    statusText.stringValue = "Aborted"
    goButton.enabled = true
    abortButton.enabled = false
    queueIndicator.integerValue = 0
  }
  
  @IBAction func go(sender: AnyObject) {
    queue.removeAll()
    for checkbox in self.series4100.subviews {
      self.process(checkbox as! NSButton)
    }
    for checkbox in self.series4200.subviews {
      self.process(checkbox as! NSButton)
    }
    if queue.isEmpty {
      queueIndicator.maxValue = 33.0
      queueIndicator.integerValue = 0
    } else {
      goButton.enabled = false
      abortButton.enabled = true
      queueIndicator.maxValue = Double(queue.count)
      queueIndicator.integerValue = 0
      downloadQueue()
    }
  }
  
   @IBAction func show(sender: AnyObject) {
    if !FILE_NAMANGER.fileExistsAtPath(FOLDER) {
      do {
        try FILE_NAMANGER.createDirectoryAtPath(FOLDER, withIntermediateDirectories: true, attributes: nil)
      } catch {
        NSLog("Can't create \(FOLDER)")
        exit(1)
      }
    }
    for checkbox in series4100.subviews {
      validate(checkbox as! NSButton)
    }
    for checkbox in series4200.subviews {
      validate(checkbox as! NSButton)
    }
    window.makeKeyAndOrderFront(self)
  }
  
  func showIfNoIndexFound() {
    var count = 0
    for key in FILES.keys {
      if let files = FILES[key] {
        for file in files {
          let path = "\(FOLDER)/\(file)"
          if FILE_NAMANGER.fileExistsAtPath(path) {
            count++
          }
        }
      }
    }
    if count == 0 {
      show(self)
    }
  }
  
}

