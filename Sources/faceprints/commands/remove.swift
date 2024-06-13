import ArgumentParser
import Foundation

struct Remove: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Remove a faceprint from the index"
  )

  @Argument(help: "The label for the faceprint")
  var label: String

  mutating func run() {
    do {
      let labelDirectory = createLabelDirectoryIfNotExists(label: label)
      try FileManager.default.removeItem(at: labelDirectory)
      printDict([
        "operation": "remove",
        "label": label,
      ])
    } catch {
      print("Error: \(error)")
    }
  }
}
