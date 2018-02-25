//
//  RawFormat.swift
//  astrometry
//
//  Created by Peter Polakovic on 27/03/2017.
//  Copyright © 2017 CloudMakers, s. r. o. All rights reserved.
//

import Cocoa

class RawImageRep: NSBitmapImageRep {
  
  override class func canInit(with data: Data) -> Bool {
    return data.starts(with: [ 0x52, 0x41, 0x57 ])
  }
  
  override class func imageReps(with data: Data) -> [NSImageRep] {
    if let imageRep = RawImageRep(data:data) {
      return [imageRep]
    }
    return []
  }
  
  let planes = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1)
  private var data: Data?
  
  public override init?(data:Data) {
    let bytes = UnsafeMutableRawPointer(mutating: (data as NSData).bytes)
    let ints = UnsafePointer<UInt32>(OpaquePointer(bytes))
    let type = ints.advanced(by: 0).pointee
    let width = Int(ints.advanced(by: 1).pointee)
    let height = Int(ints.advanced(by: 2).pointee)
    planes.pointee = UnsafeMutablePointer<UInt8>(OpaquePointer(bytes.advanced(by: 12)))
    switch indigo_raw_type(type) {
    case INDIGO_RAW_MONO8:
      super.init(bitmapDataPlanes: planes, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: NSCalibratedWhiteColorSpace, bitmapFormat:NSBitmapFormat(rawValue: 0), bytesPerRow: width, bitsPerPixel: 8)
      self.data = data
    case INDIGO_RAW_MONO16:
      super.init(bitmapDataPlanes: planes, pixelsWide: width, pixelsHigh: height, bitsPerSample: 16, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: NSCalibratedWhiteColorSpace, bitmapFormat:NSBitmapFormat(rawValue: 0), bytesPerRow: 2 * width, bitsPerPixel: 16)
      self.data = data
    case INDIGO_RAW_RGB24:
      super.init(bitmapDataPlanes: planes, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: NSDeviceRGBColorSpace, bitmapFormat:NSBitmapFormat(rawValue: 0), bytesPerRow: 3 * width, bitsPerPixel: 24)
      self.data = data
    default:
      return nil
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    planes.deallocate(capacity: 1)
  }
}
