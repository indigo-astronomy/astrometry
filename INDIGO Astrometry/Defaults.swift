//
//  Defaults.swift
//  Astrometry
//
//  Created by Polakovic Peter on 05/06/2024.
//  Copyright © 2024 CloudMakers, s. r. o. All rights reserved.
//

import Foundation

let BUNDLE = Bundle.main
let FILE_MANAGER = FileManager.default

let APPLICATION = BUNDLE.bundleIdentifier!.components(separatedBy:".").last!
let VERSION = BUNDLE.infoDictionary!["CFBundleShortVersionString"]! as! String
let BUILD = BUNDLE.infoDictionary!["CFBundleVersion"]! as! String

let FOLDER = FILE_MANAGER.containerURL(forSecurityApplicationGroupIdentifier: "AG8BXW65A2.INDIGO")!.appendingPathComponent("Data/Library/Application Support/Astrometry")

let CONFIG = FOLDER.appendingPathComponent("astrometry-0.cfg")
