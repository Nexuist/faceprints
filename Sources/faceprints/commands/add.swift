import ArgumentParser
import Foundation
import Vision

struct Add: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Add a faceprint to the index."
  )

  @OptionGroup() var args: Options

  mutating func run() {
    do {
      let labelDir = try createLabelDir(label: args.label)

      let faceImage = try? cropImage(
        inputImagePath: args.input, boundingBox: VNFaceObservation().boundingBox)
      if faceImage == nil { throw SeeVError.noSubjectFound }

      let request = VNGenerateImageFeaturePrintRequest()
      let featurePrint: [VNFeaturePrintObservation]? = try? performRequest(
        request: request, input: faceImage!)
      if featurePrint == nil { throw SeeVError.noSubjectFound }

      let embedding = featurePrint!.first!.data.withUnsafeBytes {
        Array($0.bindMemory(to: Float.self))
      }
      let embeddingData = try JSONSerialization.data(withJSONObject: embedding, options: [])
      let embeddingFile = labelDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(
        "faceprint")
      try embeddingData.write(to: embeddingFile)

      let output = [
        "status": "success",
        "message": "Added faceprint",
        "path": labelDir.path
      ] as [String : Any]
      printDict(output)
    } catch {
      print("Error: \(error)")
    }
  }
}
