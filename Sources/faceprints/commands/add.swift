import ArgumentParser
import Foundation
import Vision

struct Add: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Add a faceprint to the index"
  )

  @Argument(help: "The label for the faceprint")
  var label: String
  @OptionGroup() var args: Options

  mutating func run() {
    do {
      let faceObservations = try facesForImage(args.input)
      if faceObservations.isEmpty {
        throw FaceprintsError.noFaceFound
      }
      if faceObservations.count > 1 {
        throw FaceprintsError.multipleFacesFound
      }
      let face = faceObservations[0]
      let outputURL = try saveCroppedFace(args.input, face: face, label: label)
      recalculateAverageEmbedding(label: label)
      printDict([
        "operation": "add",
        "label": label,
        "input": args.input,
        "output": outputURL.path,
        "boundingBox": [
          "x": face.boundingBox.origin.x,
          "y": face.boundingBox.origin.y,
          "width": face.boundingBox.width,
          "height": face.boundingBox.height,
        ],
      ])
    } catch {
      print("Error: \(error)")
    }
  }
}
