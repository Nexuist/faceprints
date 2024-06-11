import Foundation

func getFaceprintsDir() -> URL {
    return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".faceprints")
}

func createLabelDir(label: String) throws -> URL {
    let labelDir = getFaceprintsDir().appendingPathComponent(label)
    try FileManager.default.createDirectory(at: labelDir, withIntermediateDirectories: true, attributes: nil)
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
