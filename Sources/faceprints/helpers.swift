import Foundation
import Vision

/**
  * Crop the image to the bounding box
  * Generate a feature print from the cropped image
  * Generate all embeddings for the images in the label directory
  * Calculate the average embedding for the label directory
  * Save it to a file in the label directory called `avg.faceprint`
*/

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
  let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".faceprints")
  createDirectoryIfNotExists(directory: homeDirectory)
  let labelDirectory = homeDirectory.appendingPathComponent(label)
  createDirectoryIfNotExists(directory: labelDirectory)
  return labelDirectory
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

func facesForImage(_ inputImagePath: String) throws -> [VNFaceObservation] {
  return try performRequest(
    request: VNDetectFaceRectanglesRequest(),
    inputImagePath: args.input
  )
}

func embeddingForFace(inputImagePath: String, face: VNFaceObservation) throws -> [Float] {
  // pass
}

func averageAndSaveAllEmbeddings(_ embeddings: [[Float]], label: String) -> [Float] {
  // pass
  // Save result to {labelDir}/avg.faceprint
}

func loadEmbeddings() -> [String: [Float]] {
  // pass
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
func cropImage(inputImagePath: String, boundingBox: CGRect) throws -> CGImage {
  let inputURL = inputImagePathToURL(inputImagePath)
  let inputImage = CIImage(contentsOf: inputURL)!
  let adjustedBoundingBox = CGRect(
    x: boundingBox.origin.x * inputImage.extent.width,
    y: boundingBox.origin.y * inputImage.extent.height,
    width: boundingBox.width * inputImage.extent.width,
    height: boundingBox.height * inputImage.extent.height
  )
  let croppedImage = inputImage.cropped(to: adjustedBoundingBox)
  let context = CIContext(options: nil)
  let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent)!
  return cgImage
}

/// Print a JSON dictionary to stdout
func printDict(_ dict: [String: Any]) {
  let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
  print(String(data: jsonData, encoding: .utf8)!)
}
