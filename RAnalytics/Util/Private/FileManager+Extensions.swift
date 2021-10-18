import Foundation

// MARK: - Database Directories

extension FileManager {
    private static let analyticsDirectoryName = "com.rakuten.tech.analytics"

    private func analyticsDirectoryURL(databaseParentDirectory: FileManager.SearchPathDirectory) -> URL? {
        switch databaseParentDirectory {
        case .documentDirectory:
            return urls(for: databaseParentDirectory, in: .userDomainMask).first

        case .applicationSupportDirectory:
            let directoryURL = urls(for: databaseParentDirectory, in: .userDomainMask).first

            guard let analyticsDirectoryURL = directoryURL?.appendingPathComponent(FileManager.analyticsDirectoryName) else {
                return nil
            }

            // Note: fileExists(atPath:) returns a Boolean value that indicates whether a file or DIRECTORY exists at a specified path.
            guard fileExists(atPath: analyticsDirectoryURL.path) else {
                do {
                    // The analytics directory does not exist, then create it:
                    try createDirectory(at: analyticsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    return analyticsDirectoryURL

                } catch {
                    return nil
                }
            }
            return analyticsDirectoryURL

        default:
            return nil
        }
    }

    func databaseFileURL(databaseName: String, databaseParentDirectory: FileManager.SearchPathDirectory) -> URL? {
        FileManager.default.analyticsDirectoryURL(databaseParentDirectory: databaseParentDirectory)?.appendingPathComponent(databaseName)
    }
}
