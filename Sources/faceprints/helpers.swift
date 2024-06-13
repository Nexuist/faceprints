import CoreImage
import Foundation
import UniformTypeIdentifiers
import Vision

let FACEPRINTS_DIRECTORY = FileManager.default.homeDirectoryForCurrentUser.appending(
  path: ".faceprints")

enum FaceprintsError: Error {
  case invalidURL
  case noFaceFound
  case multipleFacesFound
  case noFeaturePrintFound
}

enum MultimodalInput {
  case path(String)
  case url(URL)
  case raw(CGImage)
}

// Convert the input image path to a URL
func inputImagePathToURL(_ inputImagePath: String) -> URL {
  if inputImagePath.starts(with: "http") {
    return URL(string: inputImagePath)!
  } else {
    return URL(fileURLWithPath: inputImagePath)
  }
}

///MARK: Work with faceprints directory

// Create a directory if it does not exist
func createDirectoryIfNotExists(directory: URL) {
  if !FileManager.default.fileExists(atPath: directory.path) {
    try! FileManager.default.createDirectory(
      at: directory, withIntermediateDirectories: true, attributes: nil)
  }
}

// Create a label directory if it does not exist
func createLabelDirectoryIfNotExists(label: String) -> URL {
  let labelDirectory = FACEPRINTS_DIRECTORY.appendingPathComponent(label)
  createDirectoryIfNotExists(directory: labelDirectory)
  return labelDirectory
}

// Get all the labels available in the faceprints directory
func getLabels() -> [String] {
  let contents = try! FileManager.default.contentsOfDirectory(
    at: FACEPRINTS_DIRECTORY, includingPropertiesForKeys: nil)
  return contents.filter { $0.hasDirectoryPath }.map { $0.lastPathComponent }
}

// Get the average embeddings for all labels
func getFaceprints() -> [String: [Float]] {
  var faceprints = [String: [Float]]()
  for label in getLabels() {
    let labelDirectory = FACEPRINTS_DIRECTORY.appendingPathComponent(label)
    let avgEmbeddingURL = labelDirectory.appendingPathComponent("avg.faceprint")
    let data = try! Data(contentsOf: avgEmbeddingURL)
    // Convert to double first
    // Foundation/NSNumber.swift:478: Fatal error: Unable to bridge NSNumber to Float
    let rawFaceprint = try! JSONSerialization.jsonObject(with: data, options: []) as! [Double]
    let faceprint = rawFaceprint.map { Float($0) }
    faceprints[label] = faceprint
  }
  return faceprints
}

// Retrieve all PNG images in the label directory
func imagesForLabel(_ label: String) -> [URL] {
  let labelDirectory = createLabelDirectoryIfNotExists(label: label)
  let contents = try! FileManager.default.contentsOfDirectory(
    at: labelDirectory, includingPropertiesForKeys: nil)
  return contents.filter { $0.pathExtension == "png" }
}

func saveCroppedFaceToLabel(_ input: MultimodalInput, face: VNFaceObservation, label: String) throws
  -> URL
{
  // Use a UUID as the filename
  let labelDirectory = createLabelDirectoryIfNotExists(label: label)
  let outputURL = labelDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(
    "png")
  // Save the face
  let croppedImage = try croppedFace(input, face: face)
  let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(destination, croppedImage, nil)
  CGImageDestinationFinalize(destination)
  return outputURL
}

///MARK: Work with embeddings

// Calculate the embedding for the input image
func embeddingForImage(_ input: MultimodalInput) throws -> [Float] {
  let embeddings: [VNFeaturePrintObservation] = try performRequest(
    request: VNGenerateImageFeaturePrintRequest(),
    input: input
  )
  guard let embedding = embeddings.first else {
    throw FaceprintsError.noFeaturePrintFound
  }
  return embedding.data.withUnsafeBytes {
    Array($0.bindMemory(to: Float.self))
  }
}

// Generate an avg.faceprint file for the label
func recalculateAverageEmbedding(label: String) {
  // Create the label directory if it does not exist
  let labelDirectory = createLabelDirectoryIfNotExists(label: label)
  // Get all the images
  let images = imagesForLabel(label)
  // Get the embeddings for each image
  let embeddings = images.compactMap { try! embeddingForImage(.path($0.path)) }
  // Calculate the average embedding
  let averageEmbedding = embeddings.reduce([Float](repeating: 0, count: 768)) { acc, embedding in
    zip(acc, embedding).map(+)
  }.map { $0 / Float(embeddings.count) }
  // Save the average embedding to {labelDir}/avg.faceprint as a JSON file
  let avgEmbeddingURL = labelDirectory.appendingPathComponent("avg.faceprint")
  let jsonData = try! JSONSerialization.data(withJSONObject: averageEmbedding, options: [])
  try! jsonData.write(to: avgEmbeddingURL)
}

// Calculate the cosine similarity between two embeddings
func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
  let dotProduct = zip(a, b).map(*).reduce(0, +)
  let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
  let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
  return dotProduct / (magnitudeA * magnitudeB)
}

///MARK: Vision requests

// Retrieve all faces in the input image
func facesForImage(_ input: MultimodalInput) throws -> [VNFaceObservation] {
  return try performRequest(
    request: VNDetectFaceRectanglesRequest(),
    input: input
  )
}

func croppedFace(_ input: MultimodalInput, face: VNFaceObservation) throws -> CGImage {
  let inputImage: CIImage
  switch input {
  case let .path(inputImagePath):
    let inputURL = inputImagePathToURL(inputImagePath)
    inputImage = CIImage(contentsOf: inputURL)!
  case let .url(inputURL):
    inputImage = CIImage(contentsOf: inputURL)!
  case let .raw(cgImage):
    inputImage = CIImage(cgImage: cgImage)
  }
  let adjustedBoundingBox = CGRect(
    x: face.boundingBox.origin.x * inputImage.extent.width,
    y: face.boundingBox.origin.y * inputImage.extent.height,
    width: face.boundingBox.width * inputImage.extent.width,
    height: face.boundingBox.height * inputImage.extent.height
  )
  let context = CIContext(options: nil)
  let croppedImage = inputImage.cropped(to: adjustedBoundingBox)
  return context.createCGImage(croppedImage, from: croppedImage.extent)!
}

// Perform a Vision request on the input and return the results as an array of the specified type
func performRequest<T: VNObservation>(request: VNRequest, input: MultimodalInput) throws -> [T] {
  let handler: VNImageRequestHandler
  switch input {
  case let .path(inputImagePath):
    let inputURL = inputImagePathToURL(inputImagePath)
    handler = VNImageRequestHandler(url: inputURL)
  case let .url(inputURL):
    handler = VNImageRequestHandler(url: inputURL)
  case let .raw(cgImage):
    handler = VNImageRequestHandler(cgImage: cgImage)
  }
  // Get the type of what the request results are
  try handler.perform([request])
  guard let results = request.results else {
    return []
  }
  return results as! [T]
}

// Print a JSON dictionary to stdout
func printDict(_ dict: [String: Any]) {
  let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
  print(String(data: jsonData, encoding: .utf8)!)
}
