import ArgumentParser
import Foundation

struct Remove: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Remove a faceprint from the index."
  )

  @OptionGroup() var args: Options

  mutating func run() {
    do {
      let faceprintsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".faceprints")
      let labelDir = faceprintsDir.appendingPathComponent(args.label)
      try FileManager.default.removeItem(at: labelDir)
      print("Removed faceprint from \(labelDir.path)")
    } catch {
      print("Error: \(error)")
    }
  }
}
