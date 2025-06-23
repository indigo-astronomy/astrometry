//
//  AstrometryApp.swift
//  Astrometry
//
//  Created by Polakovic Peter on 05/06/2024.
//  Copyright © 2024 CloudMakers, s. r. o. All rights reserved.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  let requestURL = FOLDER.appendingPathComponent("request")
  let responseURL = FOLDER.appendingPathComponent("response")

  func applicationWillTerminate(_ notification: Notification) {
    unlink(requestURL.path)
    unlink(responseURL.path)
  }
}

@main
struct AstrometryApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    Window("INDIGO Astrometry", id: "main") {
      ContentView()
    }
  }
}
