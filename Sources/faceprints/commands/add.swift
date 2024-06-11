import ArgumentParser
import Foundation
import Vision

/**
  Add a faceprint to the index
  * Check to see if the index directory exists; make it if not
  * Check to see if the label directory exists; make it if not
  * Crop the image to the bounding box
  * Generate a feature print from the cropped image
  * Retrieve all images in the label directory
  * Generate all embeddings for the images in the label directory
  * Calculate the average embedding for the label directory
  * Save it to a file in the label directory called `avg.faceprint`
  * Return a JSON response with the `success` field (true or false) and a `count` of how many images there are
*/

struct Add: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Add a faceprint to the index."
  )

  @Argument(help: "The label for the faceprint")
  var label: String
  @OptionGroup() var args: Options

  mutating func run() {
    do {
      guard let label = args.label else {
        throw NSError(domain: "Label is required", code: 1, userInfo: nil)
      }
      let labelDir = try createLabelDir(label: label)

      let faceImage = try cropImage(
        inputImagePath: args.input, boundingBox: VNFaceObservation().boundingBox)

      let request = VNGenerateImageFeaturePrintRequest()
      let featurePrint: [VNFeaturePrintObservation] = try performRequest(
        request: request, inputImagePath: faceImage)

      let embedding = featurePrint.first!.data.withUnsafeBytes {
        Array($0.bindMemory(to: Float.self))
      }
      let embeddingData = try JSONSerialization.data(withJSONObject: embedding, options: [])
      let embeddingFile = labelDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(
        "faceprint")
      try embeddingData.write(to: embeddingFile)

      let output =
        [
          "status": "success",
          "message": "Added faceprint",
          "path": labelDir.path,
        ] as [String: Any]
      printDict(output)
    } catch {
      print("Error: \(error)")
    }
  }
}
