import ArgumentParser
import Foundation
import Helpers

struct List: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "List all faceprints in the index."
  )

  mutating func run() {
    do {
      let labels = try listLabels()
      printDict(["faceprints": labels])
    } catch {
      print("Error: \(error)")
    }
  }
}
