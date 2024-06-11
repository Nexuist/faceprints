import ArgumentParser
import Foundation

struct List: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "List all faceprints in the index."
  )

  mutating func run() {
    do {
      let faceprintsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".faceprints")
      let labels = try FileManager.default.contentsOfDirectory(atPath: faceprintsDir.path)
      print("Faceprints:")
      for label in labels {
        print("- \(label)")
      }
    } catch {
      print("Error: \(error)")
    }
  }
}
