import ArgumentParser
import Foundation

struct List: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "List all faceprints in the index"
  )

  mutating func run() {
    let labels = getLabels()
    printDict([
      "operation": "list",
      "labels": labels,
    ])
  }
}
