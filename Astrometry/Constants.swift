//
//  Constants.swift
//  astrometry
//
//  Created by Peter Polakovic on 21/12/15.
//  Copyright © 2015 CloudMakers, s. r. o. All rights reserved.
//

import Cocoa

let GREEN = NSColor(calibratedRed: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
let YELLOW = NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
let RED = NSColor(calibratedRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)

let FILE_MANAGER = FileManager.default
let WORKSPACE = NSWorkspace.shared
let DEFAULTS = UserDefaults.standard
let BUNDLE = Bundle.main
let VERSION = BUNDLE.infoDictionary!["CFBundleShortVersionString"]!
let BUILD = BUNDLE.infoDictionary!["CFBundleVersion"]!

let LEGACY_FOLDER = FILE_MANAGER.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!.appendingPathComponent("/Astrometry")
let FOLDER = FILE_MANAGER.containerURL(forSecurityApplicationGroupIdentifier: "AG8BXW65A2.INDIGO")!.appendingPathComponent("Data/Library/Application Support/Astrometry")
let CONFIG = FOLDER.appendingPathComponent("astrometry-0.cfg")

let FILES = [
  "index-4219.fits": [ "index-4219.fits" ],
  "index-4218.fits": [ "index-4218.fits" ],
  "index-4217.fits": [ "index-4217.fits" ],
  "index-4216.fits": [ "index-4216.fits" ],
  "index-4215.fits": [ "index-4215.fits" ],
  "index-4214.fits": [ "index-4214.fits" ],
  "index-4213.fits": [ "index-4213.fits" ],
  "index-4212.fits": [ "index-4212.fits" ],
  "index-4211.fits": [ "index-4211.fits" ],
  "index-4210.fits": [ "index-4210.fits" ],
  "index-4209.fits": [ "index-4209.fits" ],
  "index-4208.fits": [ "index-4208.fits" ],
  "index-4207-*.fits": [ "index-4207-00.fits", "index-4207-01.fits", "index-4207-02.fits", "index-4207-03.fits", "index-4207-04.fits", "index-4207-05.fits", "index-4207-06.fits", "index-4207-07.fits", "index-4207-08.fits", "index-4207-09.fits", "index-4207-10.fits", "index-4207-11.fits" ],
  "index-4206-*.fits": [ "index-4206-00.fits", "index-4206-01.fits", "index-4206-02.fits", "index-4206-03.fits", "index-4206-04.fits", "index-4206-05.fits", "index-4206-06.fits", "index-4206-07.fits", "index-4206-08.fits", "index-4206-09.fits", "index-4206-10.fits", "index-4206-11.fits" ],
  "index-4205-*.fits": [ "index-4205-00.fits", "index-4205-01.fits", "index-4205-02.fits", "index-4205-03.fits", "index-4205-04.fits", "index-4205-05.fits", "index-4205-06.fits", "index-4205-07.fits", "index-4205-08.fits", "index-4205-09.fits", "index-4205-10.fits", "index-4205-11.fits" ],
  "index-4204-*.fits": [ "index-4204-00.fits", "index-4204-01.fits", "index-4204-02.fits", "index-4204-03.fits", "index-4204-04.fits", "index-4204-05.fits", "index-4204-06.fits", "index-4204-07.fits", "index-4204-08.fits", "index-4204-09.fits", "index-4204-10.fits", "index-4204-11.fits", "index-4204-12.fits", "index-4204-13.fits", "index-4204-14.fits", "index-4204-15.fits", "index-4204-16.fits", "index-4204-17.fits", "index-4204-18.fits", "index-4204-19.fits", "index-4204-20.fits", "index-4204-21.fits", "index-4204-22.fits", "index-4204-23.fits", "index-4204-24.fits", "index-4204-25.fits", "index-4204-26.fits", "index-4204-27.fits", "index-4204-28.fits", "index-4204-29.fits", "index-4204-30.fits", "index-4204-31.fits", "index-4204-32.fits", "index-4204-33.fits", "index-4204-34.fits", "index-4204-35.fits", "index-4204-36.fits", "index-4204-37.fits", "index-4204-38.fits", "index-4204-39.fits", "index-4204-40.fits", "index-4204-41.fits", "index-4204-42.fits", "index-4204-43.fits", "index-4204-44.fits", "index-4204-45.fits", "index-4204-46.fits", "index-4204-47.fits" ],
  "index-4203-*.fits": [ "index-4203-00.fits", "index-4203-01.fits", "index-4203-02.fits", "index-4203-03.fits", "index-4203-04.fits", "index-4203-05.fits", "index-4203-06.fits", "index-4203-07.fits", "index-4203-08.fits", "index-4203-09.fits", "index-4203-10.fits", "index-4203-11.fits", "index-4203-12.fits", "index-4203-13.fits", "index-4203-14.fits", "index-4203-15.fits", "index-4203-16.fits", "index-4203-17.fits", "index-4203-18.fits", "index-4203-19.fits", "index-4203-20.fits", "index-4203-21.fits", "index-4203-22.fits", "index-4203-23.fits", "index-4203-24.fits", "index-4203-25.fits", "index-4203-26.fits", "index-4203-27.fits", "index-4203-28.fits", "index-4203-29.fits", "index-4203-30.fits", "index-4203-31.fits", "index-4203-32.fits", "index-4203-33.fits", "index-4203-34.fits", "index-4203-35.fits", "index-4203-36.fits", "index-4203-37.fits", "index-4203-38.fits", "index-4203-39.fits", "index-4203-40.fits", "index-4203-41.fits", "index-4203-42.fits", "index-4203-43.fits", "index-4203-44.fits", "index-4203-45.fits", "index-4203-46.fits", "index-4203-47.fits" ],
  "index-4202-*.fits": [ "index-4202-00.fits", "index-4202-01.fits", "index-4202-02.fits", "index-4202-03.fits", "index-4202-04.fits", "index-4202-05.fits", "index-4202-06.fits", "index-4202-07.fits", "index-4202-08.fits", "index-4202-09.fits", "index-4202-10.fits", "index-4202-11.fits", "index-4202-12.fits", "index-4202-13.fits", "index-4202-14.fits", "index-4202-15.fits", "index-4202-16.fits", "index-4202-17.fits", "index-4202-18.fits", "index-4202-19.fits", "index-4202-20.fits", "index-4202-21.fits", "index-4202-22.fits", "index-4202-23.fits", "index-4202-24.fits", "index-4202-25.fits", "index-4202-26.fits", "index-4202-27.fits", "index-4202-28.fits", "index-4202-29.fits", "index-4202-30.fits", "index-4202-31.fits", "index-4202-32.fits", "index-4202-33.fits", "index-4202-34.fits", "index-4202-35.fits", "index-4202-36.fits", "index-4202-37.fits", "index-4202-38.fits", "index-4202-39.fits", "index-4202-40.fits", "index-4202-41.fits", "index-4202-42.fits", "index-4202-43.fits", "index-4202-44.fits", "index-4202-45.fits", "index-4202-46.fits", "index-4202-47.fits" ],
  "index-4201-*.fits": [ "index-4201-00.fits", "index-4201-01.fits", "index-4201-02.fits", "index-4201-03.fits", "index-4201-04.fits", "index-4201-05.fits", "index-4201-06.fits", "index-4201-07.fits", "index-4201-08.fits", "index-4201-09.fits", "index-4201-10.fits", "index-4201-11.fits", "index-4201-12.fits", "index-4201-13.fits", "index-4201-14.fits", "index-4201-15.fits", "index-4201-16.fits", "index-4201-17.fits", "index-4201-18.fits", "index-4201-19.fits", "index-4201-20.fits", "index-4201-21.fits", "index-4201-22.fits", "index-4201-23.fits", "index-4201-24.fits", "index-4201-25.fits", "index-4201-26.fits", "index-4201-27.fits", "index-4201-28.fits", "index-4201-29.fits", "index-4201-30.fits", "index-4201-31.fits", "index-4201-32.fits", "index-4201-33.fits", "index-4201-34.fits", "index-4201-35.fits", "index-4201-36.fits", "index-4201-37.fits", "index-4201-38.fits", "index-4201-39.fits", "index-4201-40.fits", "index-4201-41.fits", "index-4201-42.fits", "index-4201-43.fits", "index-4201-44.fits", "index-4201-45.fits", "index-4201-46.fits", "index-4201-47.fits" ],
  "index-4200-*.fits": [ "index-4200-00.fits", "index-4200-01.fits", "index-4200-02.fits", "index-4200-03.fits", "index-4200-04.fits", "index-4200-05.fits", "index-4200-06.fits", "index-4200-07.fits", "index-4200-08.fits", "index-4200-09.fits", "index-4200-10.fits", "index-4200-11.fits", "index-4200-12.fits", "index-4200-13.fits", "index-4200-14.fits", "index-4200-15.fits", "index-4200-16.fits", "index-4200-17.fits", "index-4200-18.fits", "index-4200-19.fits", "index-4200-20.fits", "index-4200-21.fits", "index-4200-22.fits", "index-4200-23.fits", "index-4200-24.fits", "index-4200-25.fits", "index-4200-26.fits", "index-4200-27.fits", "index-4200-28.fits", "index-4200-29.fits", "index-4200-30.fits", "index-4200-31.fits", "index-4200-32.fits", "index-4200-33.fits", "index-4200-34.fits", "index-4200-35.fits", "index-4200-36.fits", "index-4200-37.fits", "index-4200-38.fits", "index-4200-39.fits", "index-4200-40.fits", "index-4200-41.fits", "index-4200-42.fits", "index-4200-43.fits", "index-4200-44.fits", "index-4200-45.fits", "index-4200-46.fits", "index-4200-47.fits" ],
  "index-4119.fits": [ "index-4119.fits" ],
  "index-4118.fits": [ "index-4118.fits" ],
  "index-4117.fits": [ "index-4117.fits" ],
  "index-4116.fits": [ "index-4116.fits" ],
  "index-4115.fits": [ "index-4115.fits" ],
  "index-4114.fits": [ "index-4114.fits" ],
  "index-4113.fits": [ "index-4113.fits" ],
  "index-4112.fits": [ "index-4112.fits" ],
  "index-4111.fits": [ "index-4111.fits" ],
  "index-4110.fits": [ "index-4110.fits" ],
  "index-4109.fits": [ "index-4109.fits" ],
  "index-4108.fits": [ "index-4108.fits" ],
  "index-4107.fits": [ "index-4107.fits" ]
]
