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
      printDict(["status": "success", "message": "Removed faceprint", "label": args.label])
    } catch {
      print("Error: \(error)")
    }
  }
}
