import ArgumentParser
import Foundation
import Vision

struct Classify: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract:
      "Classify the faces in this image using the local face index and return a JSON response."
  )

  @Flag(
    name: [.short, .long],
    help:
      "Whether to output a plaintext response (i.e. just the name of the closest label)"
  )
  var plaintext: Bool = false
  @OptionGroup() var args: Options

  mutating func run() {
    do {
      // Get all the average faceprints
      let faceprints = getFaceprints()
      let faces = try facesForImage(.path(args.input))
      guard !faces.isEmpty else {
        throw FaceprintsError.noFaceFound
      }
      var ranks: [[String: Float]] = []
      for face in faces {
        let croppedFace = try croppedFace(.path(args.input), face: face)
        let faceprint = try embeddingForImage(.raw(croppedFace))
        var faceRanks: [String: Float] = [:]
        for (label, labelFaceprint) in faceprints {
          let distance = cosineSimilarity(faceprint, labelFaceprint)
          faceRanks[label] = distance
        }
        ranks.append(faceRanks)
      }
      if plaintext {
        // Find the closest label to the first face
        let faceRanks = ranks[0]
        let closestLabel = faceRanks.max { $0.value < $1.value }!.key
        let closestDistance = faceRanks[closestLabel]!
        print("\(closestLabel) (\(closestDistance))")
      } else {
        // Print the JSON response
        printDict([
          "operation": "classify",
          "input": args.input,
          "faces": faces.enumerated().map { (index, face) in
            let topLabel = ranks[index].max { $0.value < $1.value }!.key
            return [
              "boundingBox": [
                "x": face.boundingBox.origin.x,
                "y": face.boundingBox.origin.y,
                "width": face.boundingBox.width,
                "height": face.boundingBox.height,
              ],
              "faceConfidence": face.confidence,
              "topLabel": topLabel,
              "topConfidence": ranks[index][topLabel]!,
              "ranks": ranks[index],
            ]
          },
        ])
      }
    } catch {
      print("Error: \(error)")
    }
  }
}
