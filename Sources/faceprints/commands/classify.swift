import ArgumentParser
import Foundation
import Vision

struct Classify: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract:
      "Classify the faces in this image using the local face index and return a JSON response."
  )

  @OptionGroup() var args: Options

  mutating func run() {
    // do {
    print("yolo")
    // } catch {
    //   print("Error: \(error)")
    // }
  }
}
