//
//  Logger.swift
//  Astrometry
//
//  Created by Polakovic Peter on 05/06/2024.
//  Copyright © 2024 CloudMakers, s. r. o. All rights reserved.
//

import SwiftUI
import AVFoundation

enum MessageType: Character {
  case error = "E"
  case info = "I"
  case verbose = "V"
}

class Logger: ObservableObject {
  static let shared = Logger()
  
  @Published var messages: [Message] = [ ]
  
  @AppStorage("logger.showError") var showError = true
  @AppStorage("logger.showInfo") var showInfo = true
  @AppStorage("logger.showVerbose") var showVerbose = false
  @AppStorage("logger.enableSpeach") var enableSpeach = false
  @AppStorage("logger.enableBell") var enableBell = false


  private let MAX_LINES = 500
  private let synthesizerQueue = DispatchQueue(label: "synthesizerQueue")
  private let synthesizer: AVSpeechSynthesizer?
  private var file: FileHandle
  private var fileURL: URL
  private var timeFormat = DateFormatter()
  private var beepSound: AVAudioPlayer?
  private var bookmark = 1

  init() {
    fileURL = FILE_MANAGER.temporaryDirectory.appendingPathComponent(APPLICATION)
    try? FILE_MANAGER.removeItem(at: fileURL)
    FILE_MANAGER.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    file = try! FileHandle(forUpdating: fileURL)
    timeFormat.dateFormat = "HH:mm:ss.SS"
    synthesizer = AVSpeechSynthesizer()
    if let beepPath = Bundle.main.path(forResource: "beep", ofType : "wav") {
      beepSound = try! AVAudioPlayer(contentsOf:URL(fileURLWithPath: beepPath))
    }
    Task {
      await MainActor.run {
        
      }
    }
    logMessage("Astrometry \(VERSION)-\(BUILD)")
    let task = Process()
    let pipe = Pipe()
    task.launchPath = Bundle.main.path(forAuxiliaryExecutable: "solve-field")
    task.arguments = ["--version"]
    task.standardOutput = pipe
    task.launch()
    do {
      if let data = try pipe.fileHandleForReading.readToEnd(), let line = String(data: data, encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines) {
        logMessage("Astrometry.net engine \(line)")
      } else {
        logMessage("Failed to execute Astrometry.net engine", type: .error)
      }
    } catch {
      logMessage("Failed to execute Astrometry.net engine", type: .error)
    }
  }
  
  func logMessage(_ text: String, type: MessageType = .info, speak: Bool = false) {
    Task {
      await MainActor.run {
        assert(Thread.current.isMainThread)
        let message = Message(message: "\(timeFormat.string(from: Date()))\t\(text)", type: type)
        file.write("\(message.plainString)\n".data(using: .utf8)!)
        //NSLog(text)
        addMessage(message, speak: speak)
      }
    }
  }
  
  private func playSound() {
    synthesizerQueue.async { [self] in
      if let beepSound, !beepSound.isPlaying {
        beepSound.play()
      }
    }
  }

  private func synthesizeMessage(_ message: String) {
    synthesizerQueue.async { [self] in
      if let synthesizer {
        synthesizer.speak(AVSpeechUtterance(string: message))
        while synthesizer.isSpeaking {
          sleep(1)
        }
      }
    }
  }
  
  private func addMessage(_ message: Message, speak: Bool) {
    if (showError && message.type == .error) || (showVerbose && message.type == .verbose) || (showInfo && message.type == .info) {
      if messages.count >= MAX_LINES {
        messages.removeFirst()
      }
      messages.append(message)
    }
    if enableSpeach && speak {
      synthesizeMessage(message.text)
    } else if enableBell && (message.type == .info || message.type == .error || message.type == .verbose) {
      playSound()
    }
  }

  func reset() {
    Task {
      await MainActor.run {
        messages = []
      }
      try? file.synchronize()
      let copyURL = FILE_MANAGER.temporaryDirectory.appendingPathComponent(APPLICATION + ".copy")
      try? FILE_MANAGER.removeItem(atPath: copyURL.path)
      try? FILE_MANAGER.copyItem(at: fileURL, to: copyURL)
      let bufsize = 4096
      let fp = fopen(copyURL.path, "r");
      let buf = UnsafeMutablePointer<Int8>.allocate(capacity: bufsize)
      while (fgets(buf, Int32(bufsize - 1), fp) != nil) {
        let plainString = String(cString: buf).trimmingCharacters(in: .whitespacesAndNewlines)
        if plainString.count > 2 {
          let message = Message(plainString: plainString)
          await MainActor.run {
            addMessage(message, speak: false)
          }
        }
      }
      buf.deallocate()
      fclose(fp)
      try? FILE_MANAGER.removeItem(atPath: copyURL.path)
    }
  }
  
  func addBookmark() {
    logMessage("Bookmark #\(bookmark) ------------------------------------------------------------------------------------------", speak: true)
    bookmark += 1
  }

  func save() {
    Task {
      await MainActor.run {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.canSelectHiddenExtension = true
        panel.allowedContentTypes = [ .log ]
        panel.nameFieldStringValue = "\(APPLICATION)-\(Int64(Date().timeIntervalSince1970))"
        panel.message = "Choose a folder and a name to store your log."
        let response = panel.runModal()
        if response == .OK {
          if let url = panel.url {
            Task {
              try? file.synchronize()
              try? FILE_MANAGER.copyItem(at: fileURL, to: url)
            }
          }
        }
      }
    }
  }
  
  func trash() {
    Task {
      try? FILE_MANAGER.removeItem(at: fileURL)
      FILE_MANAGER.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
      file = try! FileHandle(forUpdating: fileURL)
      reset()
    }
  }

}

class Message: Identifiable {
  let id = UUID()
  var message: String
  var type: MessageType

  init(message: String, type: MessageType) {
    self.message = message
    self.type = type
  }
  
  init(plainString: String) {
    type = MessageType(rawValue: plainString.first ?? "M")!
    message = String(plainString.suffix(from: plainString.index(plainString.startIndex, offsetBy: 2)))
  }
  
  var plainString: String {
    return "\(type.rawValue) \(message)"
  }
  
  var timestamp: String {
    String(message[...10])
  }
  
  var text: String {
    String(message[12...])
  }
  
  var attributedTimestamp: AttributedString {
    get {
      var container = AttributeContainer()
      switch type {
      case .info:
        container.foregroundColor = .systemGreen
        case .error:
          container.foregroundColor = .systemRed
        default:
          break;
      }
      return AttributedString(timestamp, attributes: container)
    }
  }
  var attributedText: AttributedString {
    get {
      var container = AttributeContainer()
      switch type {
      case .info:
        container.foregroundColor = .systemGreen
        case .error:
          container.foregroundColor = .systemRed
        default:
          break;
      }
      return AttributedString(text, attributes: container)
    }
  }
}
struct LogView: View {
  @StateObject var log = Logger.shared

  var body: some View {
    ScrollViewReader { proxy in
      VStack {
        Divider()
        ScrollView {
          ForEach($log.messages) { $message in
            VStack(alignment: .leading, spacing: 0) {
              Color.clear.frame(height: 0)
              HStack {
                Text(message.attributedTimestamp)
                  .frame(width: 80, alignment: .leading)
                  .lineLimit(1)
                Text(message.attributedText)
                  .lineLimit(1)
              }
              .id(message.id)
              .listRowSeparator(.hidden)
            }
            .padding(EdgeInsets(top: 5, leading: 5, bottom: log.messages.last?.id == message.id ? 0 : -10, trailing: 5))
            .frame(maxWidth: .infinity)
          }
        }
        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            ToolbarButton(label: "Show error messages", systemImage: "exclamationmark.bubble", state: log.showError) {
              log.showError.toggle()
              log.reset()
            }
            ToolbarButton(label: "Show information messages", systemImage: "info.bubble", state: log.showInfo) {
              log.showInfo.toggle()
              log.reset()
            }
            ToolbarButton(label: "Show more messages", systemImage: "plus.bubble", state: log.showVerbose) {
              log.showVerbose.toggle()
              log.reset()
            }
            ToolbarButton(label: "Enable speech synthesizer for some messages", systemImage: "speaker.wave.2.bubble.left", state: log.enableSpeach) {
              log.enableSpeach.toggle()
            }
            ToolbarButton(label: "Enable bell for error & warning messages", systemImage: "bell", state: log.enableBell) {
              log.enableBell.toggle()
            }
            Spacer()
            ToolbarButton(label: "Add marker", systemImage: "bookmark") {
              log.addBookmark()
            }
            ToolbarButton(label: "Save log", systemImage: "folder") {
              log.save()
            }
            ToolbarButton(label: "Trash log", systemImage: "trash") {
              log.trash()
            }
          }
        }
      }
      .task(id: log.messages.count) {
        if let id = log.messages.last?.id {
          proxy.scrollTo(id)
        }
      }
    }
  }
}

func logError(_ text: String, speak: Bool = false) {
  Logger.shared.logMessage(text, type: .error, speak: speak)
}

func logInfo(_ text: String, speak: Bool = false) {
  Logger.shared.logMessage(text, type: .info, speak: speak)
}

func logVerbose(_ text: String, speak: Bool = false) {
  Logger.shared.logMessage(text, type: .verbose, speak: speak)
}

