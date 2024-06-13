import ArgumentParser
import Foundation

struct Remove: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Remove a faceprint file from the index"
  )

  @Argument(help: "The label for the faceprint")
  var label: String
  @OptionGroup() var args: Options

  mutating func run() {
    do {
      let inputURL = FACEPRINTS_DIRECTORY.appending(path: label).appending(path: args.input)
      if !FileManager.default.fileExists(atPath: inputURL.path) {
        throw FaceprintsError.invalidURL
      }
      try FileManager.default.removeItem(at: inputURL)
      recalculateAverageEmbedding(label: label)
      printDict([
        "operation": "remove",
        "label": label,
        "input": inputURL.absoluteString,
      ])
    } catch {
      print("Error: \(error)")
    }
  }
}
