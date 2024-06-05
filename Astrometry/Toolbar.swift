//
//  Toolbar.swift
//  Astrometry
//
//  Created by Polakovic Peter on 05/06/2024.
//  Copyright © 2024 CloudMakers, s. r. o. All rights reserved.
//

import SwiftUI

struct ToolbarButton: View {
  var label: String
  var systemImage: String
  var state: Bool = false
  var action: (() -> Void)
  
  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: systemImage)
        .imageScale(.large)
        .frame(width: 24, height: 24)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .foregroundColor(state ? .accentColor : .secondary)
    }
    .foregroundColor(state ? .accentColor : .secondary)
    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.accentColor).opacity(0.0))
    .help(label)
  }
}

