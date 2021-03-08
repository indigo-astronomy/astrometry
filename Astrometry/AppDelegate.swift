//
//  AppDelegate.swift
//  Astrometry
//
//  Created by Peter Polakovic on 18.12.15.
//  Copyright © 2015 CloudMakers, s. r. o. All rights reserved.
//

import Cocoa

private var activity: NSObjectProtocol?

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet var solver: SolverDelegate!
  @IBOutlet var indexManager: IndexManagerDelegate!

  @IBAction func openProductPage(_ sender: AnyObject) {
    NSWorkspace.shared.open(URL(string: "http://www.cloudmakers.eu/astrometry")!)
  }
  
  @IBAction func openAstrometryNet(_ sender: AnyObject) {
    NSWorkspace.shared.open(URL(string: "http://www.astrometry.net")!)
  }
  
  func applicationWillFinishLaunching(_ notification: Notification) {
    NSImageRep.registerClass(RawImageRep.self)
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    do {
      try FILE_MANAGER.createDirectory(at: FOLDER, withIntermediateDirectories: true, attributes: nil)
      if let legacyFiles = try? FILE_MANAGER.contentsOfDirectory(at: LEGACY_FOLDER, includingPropertiesForKeys: nil, options: .skipsHiddenFiles), legacyFiles.count > 0 {
        for file in legacyFiles {
          if file.lastPathComponent.hasSuffix(".fits") {
            try FILE_MANAGER.moveItem(at: file, to: FOLDER.appendingPathComponent(file.lastPathComponent) )
          } else {
            try FILE_MANAGER.removeItem(at: file)
          }
        }
      }
    } catch {
      NSLog("I/O failed \(error)")
    }
    activity = ProcessInfo().beginActivity(options: ProcessInfo.ActivityOptions.background, reason: "Good Reason")
    indexManager.showIfNoIndexFound()
    solver.show(self)
    solver.startServer()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
  }
}

