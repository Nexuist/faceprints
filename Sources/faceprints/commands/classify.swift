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
      let labelEmbeddings = getLabelEmbeddings()
      let faces = try facesForImage(args.input)
      if plaintext {
        guard let face = faces.first else {
          print("No faces found")
          return
        }
        let croppedFace = try croppedFace(args.input, face: face)
        let embedding = try embeddingForImage(croppedFace)
        var closestLabel: String?
        var closestDistance: Float = 0
        for (label, labelEmbedding) in labelEmbeddings {
          let distance = cosineSimilarity(embedding, labelEmbedding.map { Float($0) })
          if distance > closestDistance {
            closestLabel = label
            closestDistance = distance
          }
        }
        if closestLabel != nil {
          print(closestLabel!)
        }
        return
      }
      // Print the JSON response
      printDict([
        "operation": "classify",
        "input": args.input,
        "faces": try faces.map {
          let croppedFace = try croppedFace(args.input, face: $0)
          let embedding = try embeddingForImage(croppedFace)
          var ranks: [[String: Float]] = []
          for (label, labelEmbedding) in labelEmbeddings {
            let distance = cosineSimilarity(embedding, labelEmbedding.map { Float($0) })
            ranks.append([label: distance])
          }
          return [
            "boundingBox": [
              "x": $0.boundingBox.origin.x,
              "y": $0.boundingBox.origin.y,
              "width": $0.boundingBox.width,
              "height": $0.boundingBox.height,
            ],
            "ranks": ranks,
          ]
        },
      ])
    } catch {
      print("Error: \(error)")
    }
  }
}
