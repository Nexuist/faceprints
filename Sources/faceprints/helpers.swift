import CoreImage
import Foundation
import Vision

let FACEPRINTS_DIRECTORY = FileManager.default.homeDirectoryForCurrentUser.appending(
  path: ".faceprints")

enum FaceprintsError: Error {
  case noFeaturePrintFound
  case invalidURL
}

/// Convert the input image path to a URL
func inputImagePathToURL(_ inputImagePath: String) -> URL {
  if inputImagePath.starts(with: "http") {
    return URL(string: inputImagePath)!
  } else {
    return URL(fileURLWithPath: inputImagePath)
  }
}

/// Create a directory if it does not exist
func createDirectoryIfNotExists(directory: URL) {
  if !FileManager.default.fileExists(atPath: directory.path) {
    try! FileManager.default.createDirectory(
      at: directory, withIntermediateDirectories: true, attributes: nil)
  }
}

/// Create a label directory if it does not exist
func createLabelDirectoryIfNotExists(label: String) -> URL {
  let labelDirectory = FACEPRINTS_DIRECTORY.appendingPathComponent(label)
  createDirectoryIfNotExists(directory: labelDirectory)
  return labelDirectory
}

/// Get all the labels available in the faceprints directory
func getLabels() -> [String] {
  let contents = try! FileManager.default.contentsOfDirectory(
    at: FACEPRINTS_DIRECTORY, includingPropertiesForKeys: nil)
  return contents.filter { $0.hasDirectoryPath }.map { $0.lastPathComponent }
}

/// Retrieve all images in the label directory
func imagesForLabel(_ label: String) -> [URL] {
  let labelDirectory = createLabelDirectoryIfNotExists(label: label)
  let contents = try! FileManager.default.contentsOfDirectory(
    at: labelDirectory, includingPropertiesForKeys: nil)
  return contents.filter {
    $0.pathExtension == "jpg" || $0.pathExtension == "jpeg" || $0.pathExtension == "png"
  }
}

/// Retrieve all faces in the input image
func facesForImage(_ inputImagePath: String) throws -> [VNFaceObservation] {
  return try performRequest(
    request: VNDetectFaceRectanglesRequest(),
    inputImagePath: inputImagePath
  )
}

func saveCroppedFace(_ inputImagePath: String, face: VNFaceObservation, label: String) {
  // Use the same filename as the input image
  // Bail if the filename already exists
  // pass
}

/// Calculate the embedding for the input image
func embeddingForImage(_ inputImagePath: String) throws -> [Float] {
  let embeddings: [VNFeaturePrintObservation] = try performRequest(
    request: VNGenerateImageFeaturePrintRequest(),
    inputImagePath: inputImagePath
  )
  guard let embedding = embeddings.first else {
    throw FaceprintsError.noFeaturePrintFound
  }
  return embedding.data.withUnsafeBytes {
    Array($0.bindMemory(to: Float.self))
  }
}

func recalculateAverageEmbedding(label: String) {
  // Save result to {labelDir}/avg.faceprint
}

/// Perform a Vision request on the input image and return the results as an array of the specified type
func performRequest<T: VNObservation>(request: VNRequest, inputImagePath: String) throws -> [T] {
  let inputURL = inputImagePathToURL(inputImagePath)
  let handler = VNImageRequestHandler(url: inputURL)
  // Get the type of what the request results are
  try handler.perform([request])
  guard let results = request.results else {
    return []
  }
  return results as! [T]
}

/// Crop the input image using the specified bounding box and return the result as a CGImage
// func cropImage(inputImagePath: String, boundingBox: CGRect) throws -> CGImage {
//   let inputURL = inputImagePathToURL(inputImagePath)
//   let inputImage = CIImage(contentsOf: inputURL)!
//   let adjustedBoundingBox = CGRect(
//     x: boundingBox.origin.x * inputImage.extent.width,
//     y: boundingBox.origin.y * inputImage.extent.height,
//     width: boundingBox.width * inputImage.extent.width,
//     height: boundingBox.height * inputImage.extent.height
//   )
//   let croppedImage = inputImage.cropped(to: adjustedBoundingBox)
//   let context = CIContext(options: nil)
//   let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent)!
//   return cgImage
// }

// func saveCGImage(_ cgImage: CGImage, name: String, label: String) {
//   // pass
// }

/// Save the output image to the specified path
// @available(macOS 11.0, *)
// func saveOutput(output: CGImage, outputImagePath: String) {
//   let outputURL = URL(fileURLWithPath: outputImagePath)
//   let destination = CGImageDestinationCreateWithURL(
//     outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
//   CGImageDestinationAddImage(destination, output, nil)
//   CGImageDestinationFinalize(destination)
// }

/// Print a JSON dictionary to stdout
func printDict(_ dict: [String: Any]) {
  let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
  print(String(data: jsonData, encoding: .utf8)!)
}
