import Foundation

// MARK: - Infographic File Storage

/// Manages on-disk storage for infographic PNG images.
/// Images are stored in the App Group container under `infographics/`.
enum InfographicStorage {

    /// Base directory for infographic images.
    static var baseDirectory: URL {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupID
        )!
        return container.appendingPathComponent("infographics", isDirectory: true)
    }

    /// Ensure the base directory exists (creates it if needed).
    static func ensureDirectoryExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseDirectory.path) {
            try fm.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }

    /// Save a PNG image to disk.
    ///
    /// - Parameters:
    ///   - imageData: Raw PNG data
    ///   - analysisID: The UUID of the associated Analysis
    ///   - index: Image index (0-based)
    /// - Returns: The file name (not full path)
    static func save(imageData: Data, for analysisID: UUID, index: Int) throws -> String {
        try ensureDirectoryExists()
        let fileName = "\(analysisID.uuidString)-\(index).png"
        let fileURL = baseDirectory.appendingPathComponent(fileName)
        try imageData.write(to: fileURL)
        return fileName
    }

    /// Load image data by file name.
    ///
    /// - Parameter fileName: The file name returned by ``save(imageData:for:index:)``
    /// - Returns: The raw image data, or nil if file not found
    static func load(fileName: String) -> Data? {
        let fileURL = baseDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    /// Delete infographic files.
    ///
    /// - Parameter fileNames: Array of file names to delete
    static func delete(fileNames: [String]) {
        let fm = FileManager.default
        for fileName in fileNames {
            let fileURL = baseDirectory.appendingPathComponent(fileName)
            try? fm.removeItem(at: fileURL)
        }
    }
}
