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
  
  func validate(_ checkbox: NSButton) {
    if let files = FILES[checkbox.title] {
      var count = 0
      for file in files {
        if FILE_MANAGER.fileExists(atPath: FOLDER.appendingPathComponent(file).path) {
          count += 1
        }
      }
      if count == 0 {
        checkbox.state = NSControl.StateValue(rawValue: 0)
      } else if count == files.count {
        checkbox.state = NSControl.StateValue(rawValue: 1)
      } else {
        checkbox.state = NSControl.StateValue(rawValue: -1)
      }
    }
  }
  
  func downloadDidBegin(_ download: NSURLDownload) {
    currentLength = 0
    DispatchQueue.main.async {
      self.fileIndicator.integerValue = 0
    }
  }
  
  func download(_ download: NSURLDownload, didReceive response: URLResponse) {
    DispatchQueue.main.async {
      self.statusText.stringValue += " (\(response.expectedContentLength) bytes)"
      self.fileIndicator.maxValue = Double(response.expectedContentLength)
    }
  }
  
  func download(_ download: NSURLDownload, didReceiveDataOfLength length: Int) {
    currentLength += length
    DispatchQueue.main.async {
      self.fileIndicator.integerValue = self.currentLength
    }
  }
  
  func downloadDidFinish(_ download: NSURLDownload) {
    DispatchQueue.main.async {
      self.downloadQueue()
    }
  }
  
  func download(_ download: NSURLDownload, didFailWithError error: Error) {
    NSLog("file failed \(error)")
    DispatchQueue.main.async {
      self.statusText.stringValue += " - failed"
      self.goButton.isEnabled = true
      self.abortButton.isEnabled = false
    }
  }
  
  func downloadQueue() {
    if let file = queue.first {
      queueIndicator.integerValue += 1
      statusText.stringValue = "Downloading \(file)"
      var url: URL?
      queue.removeFirst()
      if file.hasPrefix("index-41") {
        url = URL(string: "http://broiler.astrometry.net/~dstn/4100/\(file)")
      } else if file.hasPrefix("index-42") {
        url = URL(string: "http://broiler.astrometry.net/~dstn/4200/\(file)")
      }
      if let url = url {
        download = NSURLDownload(request: URLRequest(url: url), delegate: self)
        if let download = download {
          download.deletesFileUponFailure = true
          download.setDestination(FOLDER.appendingPathComponent(file).path, allowOverwrite: true)
        } else {
          statusText.stringValue = "Failed to download \(file)"
          goButton.isEnabled = true
          abortButton.isEnabled = false
        }
      }
    } else {
      download = nil
      statusText.stringValue = "Done"
      goButton.isEnabled = true
      abortButton.isEnabled = false
    }
  }
  
  func process(_ checkbox: NSButton) {
    let title = checkbox.title
    if let files = FILES[title] {
      for file in files {
        if FILE_MANAGER.fileExists(atPath: FOLDER.appendingPathComponent(file).path) {
          if checkbox.state.rawValue == 0 {
            WORKSPACE.recycle([URL(fileURLWithPath: file)])
            self.statusText.stringValue = "Removed \(file)"
          }
        } else {
          if checkbox.state.rawValue == 1 {
            queue.append(file)
          }
        }
      }
    }
  }
  
  @IBAction func skip2(_ sender: AnyObject) {
    let button = sender as! NSButton
    if button.state.rawValue == -1 {
      button.state = NSControl.StateValue(rawValue: 1)
    }
  }
  
  @IBAction func readme(_ sender: AnyObject) {
    NSWorkspace.shared.open(URL(string: "http://astrometry.net/doc/readme.html")!)
  }
  
  @IBAction func abort(_ sender: AnyObject) {
    queue.removeAll()
    if let download = self.download {
      download.cancel()
    }
    statusText.stringValue = "Aborted"
    goButton.isEnabled = true
    abortButton.isEnabled = false
    queueIndicator.integerValue = 0
  }
  
  @IBAction func go(_ sender: AnyObject) {
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
      goButton.isEnabled = false
      abortButton.isEnabled = true
      queueIndicator.maxValue = Double(queue.count)
      queueIndicator.integerValue = 0
      downloadQueue()
    }
  }
  
  @IBAction func show(_ sender: AnyObject) {
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
          if FILE_MANAGER.fileExists(atPath: FOLDER.appendingPathComponent(file).path) {
            count += 1
          }
        }
      }
    }
    if count == 0 {
      show(self)
    }
  }
}

