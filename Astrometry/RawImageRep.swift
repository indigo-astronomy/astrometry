//
//  INDIGORawImage.swift
//  astrometry
//
//  Created by Peter Polakovic on 06/07/2017.
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
    let pixels = UnsafeMutablePointer<UInt8>(OpaquePointer(bytes.advanced(by: 12)))
    let ints = UnsafePointer<UInt32>(OpaquePointer(bytes))
    let type = ints.advanced(by: 0).pointee
    let width = Int(ints.advanced(by: 1).pointee)
    let height = Int(ints.advanced(by: 2).pointee)
    planes.pointee = pixels
    switch type {
    case 0x31574152: // INDIGO_RAW_MONO8
      super.init(bitmapDataPlanes: planes, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: NSCalibratedWhiteColorSpace, bitmapFormat:NSBitmapFormat(rawValue: 0), bytesPerRow: width, bitsPerPixel: 8)
      self.data = data
    case 0x32574152: // INDIGO_RAW_MONO16
      super.init(bitmapDataPlanes: planes, pixelsWide: width, pixelsHigh: height, bitsPerSample: 16, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: NSCalibratedWhiteColorSpace, bitmapFormat:NSBitmapFormat(rawValue: 0), bytesPerRow: 2 * width, bitsPerPixel: 16)
      self.data = data
    case 0x33574152: // INDIGO_RAW_RGB24
      let size = width * height
      for i in 0..<size {
        let i3 = 3 * i
        let t = pixels.advanced(by: i3).pointee
        pixels.advanced(by: i3).pointee = pixels.advanced(by: i3 + 2).pointee
        pixels.advanced(by: i3 + 2).pointee = t
      }
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
