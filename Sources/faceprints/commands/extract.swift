import ArgumentParser
import Foundation

struct Extract: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract:
      "Calculate the embedding for a face in the photo and output it as a JSON array of 768 floats"
  )

  @OptionGroup() var args: Options

  mutating func run() {
    do {
      let faces = try facesForImage(.path(args.input))
      guard let face = faces.first else {
        throw FaceprintsError.noFaceFound
      }
      let croppedFace = try croppedFace(.path(args.input), face: face)
      let embedding = try embeddingForImage(.raw(croppedFace))
      print(embedding)
    } catch {
      print("Error: \(error)")
    }
  }
}
