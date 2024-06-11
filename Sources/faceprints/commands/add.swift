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
      let faceprintsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".faceprints")
      let labelDir = faceprintsDir.appendingPathComponent(args.label)
      try FileManager.default.createDirectory(at: labelDir, withIntermediateDirectories: true, attributes: nil)

      let faceImage = try? cropImage(inputImagePath: args.input, boundingBox: VNFaceObservation().boundingBox)
      if faceImage == nil { throw SeeVError.noSubjectFound }

      let request = VNGenerateImageFeaturePrintRequest()
      let featurePrint: [VNFeaturePrintObservation]? = try? performRequest(request: request, input: faceImage!)
      if featurePrint == nil { throw SeeVError.noSubjectFound }

      let embedding = featurePrint!.first!.data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
      let embeddingData = try JSONSerialization.data(withJSONObject: embedding, options: [])
      let embeddingFile = labelDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("faceprint")
      try embeddingData.write(to: embeddingFile)

      print("Added faceprint to \(labelDir.path)")
    } catch {
      print("Error: \(error)")
    }
  }
}
