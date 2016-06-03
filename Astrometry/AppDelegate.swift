//
//  AppDelegate.swift
//  Astrometry
//
//  Created by Peter Polakovic on 18.12.15.
//  Copyright © 2015 CloudMakers, s. r. o. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet var solver: SolverDelegate!
  @IBOutlet var indexManager: IndexManagerDelegate!

  @IBAction func openProductPage(sender: AnyObject) {
    NSWorkspace.sharedWorkspace().openURL(NSURL(string: "http://www.cloudmakers.eu/astrometry")!)
  }
  
  @IBAction func openAstrometryNet(sender: AnyObject) {
    NSWorkspace.sharedWorkspace().openURL(NSURL(string: "http://www.astrometry.net")!)
  }
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
    if !FILE_NAMANGER.fileExistsAtPath(CONFIG) {
      if let config = "cpulimit 300\nadd_path \(FOLDER)\nautoindex\n".dataUsingEncoding(NSASCIIStringEncoding) {
        config.writeToFile(CONFIG, atomically: true)
      }
    }
    indexManager.showIfNoIndexFound()
    solver.show(self)
    solver.startServer()
  }

  func applicationWillTerminate(aNotification: NSNotification) {
  }
}

