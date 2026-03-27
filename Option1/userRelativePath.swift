private let userRelativePathRegex = /^\/Users\/(.*?)\/\b/

func userRelativePath(_ path: String) -> String {
    path.replacing(userRelativePathRegex, with: "~/")
}
