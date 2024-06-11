import ArgumentParser
import Foundation
import Helpers

struct Remove: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Remove a faceprint from the index."
  )

  @OptionGroup() var args: Options

  mutating func run() {
    do {
      try removeLabelDir(label: args.label)
      print("Removed faceprint from \(labelDir.path)")
    } catch {
      print("Error: \(error)")
    }
  }
}
