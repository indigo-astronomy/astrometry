//
//  ContentView.swift
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

actor SpeechSynthetizer {
  private let synthesizer = AVSpeechSynthesizer()
  private var beepSound: AVAudioPlayer?

  init() {
    if let beepPath = Bundle.main.path(forResource: "beep", ofType : "wav") {
      beepSound = try! AVAudioPlayer(contentsOf:URL(fileURLWithPath: beepPath))
    }
  }
  
  func beep() {
    if let beepSound, !beepSound.isPlaying {
      beepSound.play()
    }
  }
  
  func speak(_ message: String) {
    synthesizer.speak(AVSpeechUtterance(string: message))
    while synthesizer.isSpeaking {
      sleep(1)
    }
  }
}

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

class Logger: ObservableObject {
  static let shared = Logger()
  
  @Published var messages: [Message] = [ ]
  
  @AppStorage("logger.showError") var showError = true
  @AppStorage("logger.showInfo") var showInfo = true
  @AppStorage("logger.showVerbose") var showVerbose = false
  @AppStorage("logger.enableSpeach") var enableSpeach = false
  @AppStorage("logger.enableBell") var enableBell = false

  private let MAX_LINES = 200
  private var file: FileHandle
  private var fileURL: URL
  private var timeFormat = DateFormatter()
  private var synthetizer = SpeechSynthetizer()
  private var bookmark = 1

  init() {
    fileURL = FILE_MANAGER.temporaryDirectory.appendingPathComponent(APPLICATION)
    try? FILE_MANAGER.removeItem(at: fileURL)
    FILE_MANAGER.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    file = try! FileHandle(forUpdating: fileURL)
    timeFormat.dateFormat = "HH:mm:ss.SS"
    let osInfo = ProcessInfo.processInfo.operatingSystemVersion
    let task = Process()
    let pipe = Pipe()
    task.launchPath = Bundle.main.path(forAuxiliaryExecutable: "solve-field")
    task.arguments = ["--version"]
    task.standardOutput = pipe
    task.launch()
    if let engineVersion = pipe.fileHandleForReading.readLine() {
      logMessage("INDIGO Astrometry \(VERSION)-\(BUILD), Astrometry.net engine \(engineVersion), macOS \(osInfo.majorVersion).\(osInfo.minorVersion).\(osInfo.patchVersion)")
    } else {
      logMessage("INDIGO Astrometry \(VERSION)-\(BUILD), Astrometry.net engine failed to load, macOS \(osInfo.majorVersion).\(osInfo.minorVersion).\(osInfo.patchVersion)")
    }
  }
  
  func logMessage(_ text: String, type: MessageType = .info, speak: Bool = false) {
    NSLog(text)
    Task {
      await MainActor.run {
        assert(Thread.current.isMainThread)
        let message = Message(message: "\(timeFormat.string(from: Date()))\t\(text)", type: type)
        file.write("\(message.plainString)\n".data(using: .utf8)!)
        addMessage(message, speak: speak)
      }
    }
  }
  
  private func playSound() {
    Task {
      await synthetizer.beep()
    }
  }

  private func synthesizeMessage(_ message: String) {
    Task {
      await synthetizer.speak(_:message)
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
    type = MessageType(rawValue: plainString.first ?? "V")!
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
  @StateObject var logger = Logger.shared

  var body: some View {
    ScrollViewReader { proxy in
      VStack {
        Divider()
        ScrollView {
          ForEach($logger.messages) { $message in
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
            .padding(EdgeInsets(top: 5, leading: 5, bottom: logger.messages.last?.id == message.id ? 0 : -10, trailing: 5))
            .frame(maxWidth: .infinity)
          }
        }
        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            ToolbarButton(label: "Show error messages", systemImage: "exclamationmark.bubble", state: logger.showError) {
              logger.showError.toggle()
              logger.reset()
            }
            ToolbarButton(label: "Show information messages", systemImage: "info.bubble", state: logger.showInfo) {
              logger.showInfo.toggle()
              logger.reset()
            }
            ToolbarButton(label: "Show more messages", systemImage: "plus.bubble", state: logger.showVerbose) {
              logger.showVerbose.toggle()
              logger.reset()
            }
            ToolbarButton(label: "Enable speech synthesizer for some messages", systemImage: "speaker.wave.2.bubble.left", state: logger.enableSpeach) {
              logger.enableSpeach.toggle()
            }
            ToolbarButton(label: "Enable bell for error & warning messages", systemImage: "bell", state: logger.enableBell) {
              logger.enableBell.toggle()
            }
            ToolbarButton(label: "Add marker", systemImage: "bookmark") {
              logger.addBookmark()
            }
            ToolbarButton(label: "Save log", systemImage: "folder") {
              logger.save()
            }
            ToolbarButton(label: "Trash log", systemImage: "trash") {
              logger.trash()
            }
          }
        }
      }
      .task(id: logger.messages.count) {
        if let id = logger.messages.last?.id {
          proxy.scrollTo(id)
        }
      }
    }
  }
}

struct ContentView: View {
  @State var isBusy = false
  
  func execute(_ executable: String, arguments: [String], result: FileHandle? = nil) {
    var ok = false
    let start = Date().timeIntervalSince1970
    Logger.shared.logMessage("Processing request...", type: .info, speak: true)
    Logger.shared.logMessage(executable + arguments.joined(separator: " "), type: .verbose)
    let task = Process()
    let pipe = Pipe()
    task.launchPath = Bundle.main.path(forAuxiliaryExecutable: executable)
    task.currentDirectoryPath = FOLDER.path
    task.environment = [ "TMP": NSTemporaryDirectory()]
    task.arguments = arguments
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    while true {
      if let line = pipe.fileHandleForReading.readLine() {
        if !line.isEmpty {
          if line.hasPrefix("Did not solve") {
            Logger.shared.logMessage(line, type: .error)
            ok = false
          } else if line.hasPrefix("simplexy: found ") && line.hasSuffix("sources.") {
            Logger.shared.logMessage("Found \(line[16...])", type: .info)
            ok = true
          } else if line.hasPrefix("Field center:") || line.hasPrefix("Field size:") || line.hasPrefix("Field rotation angle:") || line.hasPrefix("Field parity:") {
            Logger.shared.logMessage(line, type: .info)
            ok = true
          } else {
            Logger.shared.logMessage(line, type: .verbose)
          }
        }
        result?.writeLine(line)
      } else {
        break
      }
    }
    usleep(100000)
    if task.terminationStatus == 0 && ok {
      let elapsed = Date().timeIntervalSince1970 - start
      if elapsed < 1 {
        Logger.shared.logMessage("Done in \(Int(round(elapsed * 1000))) milliseconds", type: .info, speak: true)
      } else {
        Logger.shared.logMessage("Done in \(round((elapsed * 10) / 10)) seconds", type: .info, speak: true)
      }
    } else {
      Logger.shared.logMessage("Failed", type: .error, speak: true)
      if task.terminationStatus == 15 {
        Logger.shared.logMessage("\(executable) aborted", type: .verbose)
      } else if task.terminationStatus != 0 {
        Logger.shared.logMessage("\(executable) terminated (status \(task.terminationStatus))", type: .verbose)
      }
    }
  }
  
  var body: some View {
    VStack {
      LogView()
    }
    .onAppear() {
      Task.detached {
        let requestURL = FOLDER.appendingPathComponent("request")
        let responseURL = FOLDER.appendingPathComponent("response")
        Logger.shared.logMessage("IPC listener started", type: .info, speak: true)
        while true {
          if let requestHandle = try? FileHandle(forReadingFrom: requestURL), let responseHandle = try? FileHandle(forWritingTo: responseURL) {
            if isBusy {
              responseHandle.writeLine("message: Solver is busy")
              responseHandle.writeLine("<<<EOF>>>")
              responseHandle.closeFile()
              requestHandle.closeFile()
            } else {
              isBusy = true
              var args = [String]()
              while isBusy {
                if let line = requestHandle.readLine() {
                  if line == "<<<EOF>>>" {
                    let command = args.removeFirst()
                    execute(command, arguments: args, result: responseHandle)
                    isBusy = false
                    responseHandle.writeLine("<<<EOF>>>")
                    responseHandle.closeFile()
                    requestHandle.closeFile()
                    break
                  } else {
                    args.append(line)
                  }
                } else {
                  isBusy = false
                }
              }
            }
          } else {
            break
          }
        }
        Logger.shared.logMessage("Failed to create named pipe for IPC", type: .error, speak: true)
      }
    }
  }
}
