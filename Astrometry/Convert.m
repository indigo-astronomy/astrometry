//
//  Convert.m
//  astrometry
//
//  Created by Peter Polakovic on 27/12/2016.
//  Copyright © 2016 CloudMakers, s. r. o. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include "fitsio.h"

bool Convert(NSString *input, NSString *output) {
  NSImage *image;
  if ([input hasSuffix:@".nef"] || [input hasSuffix:@".cr2"]) {
    NSURL *url = [NSURL fileURLWithPath:input];
    image = [[NSImage alloc] initWithContentsOfURL:url];
  } else {
    image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfFile:input]];
  }
  NSBitmapImageRep* imageRep = (NSBitmapImageRep *)[image.representations firstObject];
  if (imageRep != NULL) {
    int width = (int)imageRep.pixelsWide;
    int height = (int)imageRep.pixelsHigh;
    int length = 2*width*height;
    uint16_t *body = malloc(length);
    int i = 0;
    if ([imageRep bitsPerPixel] == 8) {
      for (int y = 0; y < height; y++) {
        uint8_t *data = (uint8_t *)([imageRep bitmapData]+y*[imageRep bytesPerRow]);
        for (int x = 0; x < width; x++) {
          body[i++] = *data++;
        }
      }
    } else if ([imageRep bitsPerPixel] == 16) {
      for (int y = 0; y < height; y++) {
        uint16_t *data = (uint16_t *)([imageRep bitmapData]+y*[imageRep bytesPerRow]);
        for (int x = 0; x < width; x++) {
          body[i++] = *data++;
        }
      }
    } else if ([imageRep bitsPerPixel] == 24) {
      for (int y = 0; y < height; y++) {
        uint8_t *data = (uint8_t *)([imageRep bitmapData]+y*[imageRep bytesPerRow]);
        for (int x = 0; x < width; x++) {
          body[i++] = (data[0] + data[1] + data[2]);
          data += 3;
        }
      }
    } else if ([imageRep bitsPerPixel] == 32) {
      for (int y = 0; y < height; y++) {
        uint8_t *data = (uint8_t *)([imageRep bitmapData]+y*[imageRep bytesPerRow]);
        for (int x = 0; x < width; x++) {
          body[i++] = (data[0] + data[1] + data[2]);
          data += 4;
        }
      }
    } else if ([imageRep bitsPerPixel] == 48) {
      for (int y = 0; y < height; y++) {
        uint16_t *data = (uint16_t *)([imageRep bitmapData]+y*[imageRep bytesPerRow]);
        for (int x = 0; x < width; x++) {
          body[i++] = (data[0] + data[1] + data[2]) / 3;
          data += 3;
        }
      }
    }
      //NSLog(@"%ld %dx%d", (long)[imageRep bitsPerPixel], width, height);
    fitsfile *fptr;
    char *fileName = (char *)[output cStringUsingEncoding:NSASCIIStringEncoding];
    int status = 0, bitpix = SHORT_IMG, naxis = 2, exists;
    long naxes[2], fpixel[] = { 1, 1 };
    fits_file_exists(fileName, &exists, &status);
    if (exists > 0) {
      [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:fileName] error:nil];
    }    
    if (!fits_create_file(&fptr, fileName, &status)) {
      naxes[0] = width;
      naxes[1] = height;
        naxis = 2;
      fits_create_img(fptr, bitpix, naxis, naxes, &status);
      fits_write_pix(fptr, TUSHORT, fpixel, width * height, body, &status);
      fits_close_file(fptr, &status);
      free(body);
      return true;
    }
    free(body);
  }
  return false;
}
