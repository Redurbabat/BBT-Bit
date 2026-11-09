import Foundation

enum ReleaseRepository {
    static let name = "Redurbabat/RED-Bit"
    static let latestPage = URL(string: "https://github.com/\(name)/releases/latest")!
    static let latestAPI = URL(string: "https://api.github.com/repos/\(name)/releases/latest")!
    static func accepts(page: URL) -> Bool {
        page.scheme == "https" && page.host == "github.com" && page.user == nil && page.password == nil
            && (page.port == nil || page.port == 443)
            && page.path.hasPrefix("/\(name)/releases/tag/")
    }
    static func assetPrefix(tag: String) -> String { "/\(name)/releases/download/\(tag)/" }
    static func accepts(asset: URL) -> Bool {
        asset.scheme == "https" && asset.host == "github.com" && asset.user == nil && asset.password == nil
            && (asset.port == nil || asset.port == 443)
            && asset.path.hasPrefix("/\(name)/releases/download/") && !asset.path.contains("..")
    }
}
