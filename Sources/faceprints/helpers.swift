import Foundation

func getFaceprintsDir() -> URL {
    return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".faceprints")
}

func createLabelDir(label: String) throws -> URL {
    let labelDir = getFaceprintsDir().appendingPathComponent(label)
    if !FileManager.default.fileExists(atPath: labelDir.path) {
        try FileManager.default.createDirectory(at: labelDir, withIntermediateDirectories: true, attributes: nil)
    } else {
        throw NSError(domain: "Label directory already exists", code: 1, userInfo: nil)
    }
    return labelDir
}

func listLabels() throws -> [String] {
    return try FileManager.default.contentsOfDirectory(atPath: getFaceprintsDir().path)
}

func removeLabelDir(label: String) throws {
    let labelDir = getFaceprintsDir().appendingPathComponent(label)
    try FileManager.default.removeItem(at: labelDir)
}

func printDict(_ dict: [String: Any]) {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    } catch {
        print("Error serializing JSON: \(error)")
    }
}

func cropImage(inputImagePath: String, boundingBox: CGRect) throws -> CGImage {
    let url = URL(fileURLWithPath: inputImagePath)
    let ciImage = CIImage(contentsOf: url)!
    let context = CIContext(options: nil)
    let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!

    let width = CGFloat(cgImage.width)
    let height = CGFloat(cgImage.height)

    let cropRect = CGRect(
        x: boundingBox.origin.x * width,
        y: (1 - boundingBox.origin.y - boundingBox.height) * height,
        width: boundingBox.width * width,
        height: boundingBox.height * height
    )

    return cgImage.cropping(to: cropRect)!
}
