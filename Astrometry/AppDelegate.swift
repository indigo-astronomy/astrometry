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
    NSWorkspace.shared().open(URL(string: "http://www.cloudmakers.eu/astrometry")!)
  }
  
  @IBAction func openAstrometryNet(_ sender: AnyObject) {
    NSWorkspace.shared().open(URL(string: "http://www.astrometry.net")!)
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSImageRep.registerClass(RawImageRep.self)
    if !FILE_NAMANGER.fileExists(atPath: CONFIG) {
      if let config = "cpulimit 300\nadd_path \(FOLDER)\nautoindex\n".data(using: String.Encoding.ascii) {
        try? config.write(to: URL(fileURLWithPath: CONFIG), options: [.atomic])
      }
    }
    activity = ProcessInfo().beginActivity(options: ProcessInfo.ActivityOptions.background, reason: "Good Reason")
    indexManager.showIfNoIndexFound()
    solver.show(self)
    solver.startServer()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
  }
}

