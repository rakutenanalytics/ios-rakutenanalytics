#!/usr/bin/env swift

import Foundation

private let schemaRepositoryPath =
    "github.com/rakutenanalytics/rakuten-analytics-json-schema.git"

private let schemaRelativePath = "schemas/base-non-strict.json"

private let payloadParameterKeysPath = "Sources/Main/Util/Private/PayloadParameterKeys.swift"

private typealias SchemaNode = [String: Any]

private enum GeneratorError: Error, LocalizedError {
    case invalidArguments(String)
    case gitCloneFailed(String)
    case schemaReadFailed(String)
    case schemaParseFailed(String)
    case invalidSchema(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let message):
            message
        case .gitCloneFailed(let message):
            message
        case .schemaReadFailed(let message):
            message
        case .schemaParseFailed(let message):
            message
        case .invalidSchema(let message):
            message
        }
    }
}

private func parseArguments(_ arguments: [String]) throws -> (schemaVersion: String?, outputPath: String?) {
    var schemaVersion: String?
    var outputPath: String?
    var index = 0

    while index < arguments.count {
        let argument = arguments[index]

        if argument == "--version" {
            guard index + 1 < arguments.count else {
                throw GeneratorError.invalidArguments("Missing value for --version")
            }
            schemaVersion = arguments[index + 1]
            index += 2
        } else if outputPath == nil {
            outputPath = argument
            index += 1
        } else {
            throw GeneratorError.invalidArguments("Unknown argument: \(argument)")
        }
    }

    return (schemaVersion, outputPath)
}

private func schemaVersionRef(_ version: String) -> String {
    version.hasPrefix("v") ? version : "v\(version)"
}

private struct SchemaRepositoryCredentials {
    let username: String
    let token: String
}

private func schemaRepositoryCloneURL() -> String {
    "https://\(schemaRepositoryPath)"
}

/// Reads the clone credentials without ever placing them in a URL, so they can't leak via
/// process listings or logs; callers should hand them to git through an askpass helper instead.
private func schemaRepositoryCredentials() throws -> SchemaRepositoryCredentials? {
    let environment = ProcessInfo.processInfo.environment
    let username = environment["PRIVATE_GITHUB_USERNAME"]
    let token = environment["PRIVATE_GITHUB_TOKEN"]

    let hasUsername = !(username?.isEmpty ?? true)
    let hasToken = !(token?.isEmpty ?? true)

    if !hasUsername && !hasToken {
        return nil
    }

    guard hasUsername, hasToken, let username, let token else {
        throw GeneratorError.invalidArguments(
            "Both PRIVATE_GITHUB_USERNAME and PRIVATE_GITHUB_TOKEN must be set to clone the schema repository with credentials."
        )
    }

    return SchemaRepositoryCredentials(username: username, token: token)
}

/// Writes a short-lived GIT_ASKPASS helper that hands git the credentials via environment
/// variables rather than argv/URL, so they never appear in `ps` output or shell history.
private func makeAskpassScript(in directory: URL) throws -> URL {
    let scriptURL = directory.appendingPathComponent("git-askpass.sh")
    let script = """
    #!/bin/sh
    case "$1" in
        Username*) printf '%s' "$RAT_SCHEMA_GIT_USERNAME" ;;
        *) printf '%s' "$RAT_SCHEMA_GIT_TOKEN" ;;
    esac
    """

    try script.write(to: scriptURL, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)

    return scriptURL
}

private func definitionLevels(from node: SchemaNode) -> [String] {
    guard let value = node["x-definitionLevel"] as? [Any],
          !value.isEmpty,
          value.allSatisfy({ $0 is String }) else {
        return []
    }

    return value.compactMap { $0 as? String }
}

private func isSdkLayerLevel(_ node: SchemaNode) -> Bool {
    (node["x-layerLevel"] as? String) == "SDK"
}

/// A schema node is available on iOS only when:
///
/// - x-definitionLevel exists;
/// - x-definitionLevel is a non-empty array;
/// - x-definitionLevel contains "iOS";
/// - x-layerLevel is equal to "SDK".
///
/// x-definitionLevel alone is not enough, as it does not distinguish SDK
/// parameters from App parameters. Missing or empty definition levels are
/// not inherited from the parent.
private func includesIOSSDK(_ node: SchemaNode) -> Bool {
    definitionLevels(from: node).contains("iOS") && isSdkLayerLevel(node)
}

private func swiftIdentifier(for jsonKey: String) -> String {
    let camelCasedPattern = try! NSRegularExpression(pattern: #"[_-]+([a-zA-Z0-9])"#)
    var camelCased = jsonKey
    while true {
        let range = NSRange(camelCased.startIndex..<camelCased.endIndex, in: camelCased)
        guard let match = camelCasedPattern.firstMatch(in: camelCased, range: range),
              match.numberOfRanges == 2,
              let fullRange = Range(match.range(at: 0), in: camelCased),
              let captureRange = Range(match.range(at: 1), in: camelCased) else {
            break
        }

        let captured = String(camelCased[captureRange])
        camelCased.replaceSubrange(fullRange, with: captured.uppercased())
    }

    let sanitizedPattern = try! NSRegularExpression(pattern: #"[^a-zA-Z0-9_]"#)
    let sanitized = sanitizedPattern.stringByReplacingMatches(
        in: camelCased,
        range: NSRange(camelCased.startIndex..<camelCased.endIndex, in: camelCased),
        withTemplate: "_"
    )

    let identifier = sanitized.first?.isNumber == true ? "_\(sanitized)" : sanitized

    return identifier
}

private func swiftTypeName(for jsonKey: String) -> String {
    let name = swiftIdentifier(for: jsonKey).replacingOccurrences(of: "`", with: "")
    return name.prefix(1).uppercased() + name.dropFirst()
}

private func escapeSwiftString(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\r\n", with: " ")
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
}

private func normalizeDoc(_ value: String?) -> String? {
    guard var text = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !text.isEmpty else {
        return nil
    }

    let brPattern = try! NSRegularExpression(pattern: #"<br\s*/?\s*>"#, options: .caseInsensitive)
    let tagPattern = try! NSRegularExpression(pattern: #"<[^>]+>"#)
    let whitespacePattern = try! NSRegularExpression(pattern: #"\s+"#)

    let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
    text = brPattern.stringByReplacingMatches(in: text, range: fullRange, withTemplate: " ")
    let tagRange = NSRange(text.startIndex..<text.endIndex, in: text)
    text = tagPattern.stringByReplacingMatches(in: text, range: tagRange, withTemplate: "")
    let whitespaceRange = NSRange(text.startIndex..<text.endIndex, in: text)
    text = whitespacePattern.stringByReplacingMatches(in: text, range: whitespaceRange, withTemplate: " ")
    text = text.trimmingCharacters(in: .whitespacesAndNewlines)

    return text.isEmpty ? nil : text
}

private func emitDocumentation(for node: SchemaNode, indent: String) -> [String] {
    let description: String? = if let nodeDescription = node["description"] as? String {
        normalizeDoc(nodeDescription)
    } else if let englishDescription = node["x-enDescription"] as? String {
        normalizeDoc(englishDescription)
    } else if let title = node["title"] as? String {
        normalizeDoc(title)
    } else {
        nil
    }

    guard let description else {
        return []
    }
    return ["\(indent)/// \(description)"]
}

private func emitConstant(
    jsonKey: String,
    node: SchemaNode,
    indent: String
) -> [String] {
    var lines = emitDocumentation(for: node, indent: indent)
    lines.append(
        "\(indent)static let \(swiftIdentifier(for: jsonKey)) = \"\(escapeSwiftString(jsonKey))\""
    )
    return lines
}

/// Nested properties must explicitly declare iOS support.
///
/// A child with a missing or empty x-definitionLevel is excluded, even when
/// its parent includes iOS.
private func childIsAvailableOnIOS(_ child: SchemaNode) -> Bool {
    includesIOSSDK(child)
}

/// Extracts top-level JSON object keys in source order.
private func extractTopLevelJSONKeys(from objectBody: String) -> [String] {
    var keys: [String] = []
    var index = objectBody.startIndex
    var depth = 0
    var inString = false
    var escaped = false
    var collectingKey = false
    var keyStart: String.Index?

    while index < objectBody.endIndex {
        let char = objectBody[index]

        if inString {
            if escaped {
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "\"" {
                inString = false
                if collectingKey, let start = keyStart {
                    keys.append(String(objectBody[start..<index]))
                    collectingKey = false
                    keyStart = nil
                }
            }
        } else {
            switch char {
            case "\"":
                inString = true
                if depth == 0 {
                    collectingKey = true
                    keyStart = objectBody.index(after: index)
                }
            case "{":
                depth += 1
            case "}":
                if depth == 0 {
                    return keys
                }
                depth -= 1
            case "[":
                depth += 1
            case "]":
                depth -= 1
            default:
                break
            }
        }

        index = objectBody.index(after: index)
    }

    return keys
}

private func findMatchingBraceEnd(in text: String, openingBraceAt: String.Index) -> String.Index? {
    guard text[openingBraceAt] == "{" else {
        return nil
    }

    var index = text.index(after: openingBraceAt)
    var depth = 1
    var inString = false
    var escaped = false

    while index < text.endIndex {
        let char = text[index]

        if inString {
            if escaped {
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "\"" {
                inString = false
            }
        } else {
            switch char {
            case "\"":
                inString = true
            case "{":
                depth += 1
            case "}":
                depth -= 1
                if depth == 0 {
                    return index
                }
            default:
                break
            }
        }

        index = text.index(after: index)
    }

    return nil
}

private func extractDefsBody(from rawJSON: String) -> String? {
    let defsPattern = #""\$defs"\s*:\s*\{"#

    guard let defsRegex = try? NSRegularExpression(pattern: defsPattern),
          let defsMatch = defsRegex.firstMatch(
            in: rawJSON,
            range: NSRange(rawJSON.startIndex..., in: rawJSON)
          ),
          let defsMatchRange = Range(defsMatch.range, in: rawJSON) else {
        return nil
    }

    let defsOpenBrace = rawJSON.index(before: defsMatchRange.upperBound)
    guard let defsCloseBrace = findMatchingBraceEnd(in: rawJSON, openingBraceAt: defsOpenBrace) else {
        return nil
    }

    let defsBodyStart = rawJSON.index(after: defsOpenBrace)
    return String(rawJSON[defsBodyStart..<defsCloseBrace])
}

private func orderedPropertyKeys(definitionKey: String, in rawJSON: String) -> [String] {
    guard let defsBody = extractDefsBody(from: rawJSON) else {
        return []
    }

    let escapedKey = NSRegularExpression.escapedPattern(for: definitionKey)
    let definitionPattern = #""\#(escapedKey)"\s*:\s*\{"#

    guard let definitionRegex = try? NSRegularExpression(pattern: definitionPattern),
          let definitionMatch = definitionRegex.firstMatch(
            in: defsBody,
            range: NSRange(defsBody.startIndex..., in: defsBody)
          ),
          let definitionOpenEnd = Range(definitionMatch.range, in: defsBody)?.upperBound else {
        return []
    }

    let tail = String(defsBody[definitionOpenEnd...])
    let propertiesPattern = #""properties"\s*:\s*\{"#

    guard let propertiesRegex = try? NSRegularExpression(pattern: propertiesPattern),
          let propertiesMatch = propertiesRegex.firstMatch(
            in: tail,
            range: NSRange(tail.startIndex..., in: tail)
          ),
          let propertiesMatchRange = Range(propertiesMatch.range, in: tail) else {
        return []
    }

    let propertiesOpenBrace = tail.index(before: propertiesMatchRange.upperBound)
    guard let propertiesCloseBrace = findMatchingBraceEnd(in: tail, openingBraceAt: propertiesOpenBrace) else {
        return []
    }

    let propertiesBodyStart = tail.index(after: propertiesOpenBrace)
    let propertiesBody = String(tail[propertiesBodyStart..<propertiesCloseBrace])
    return extractTopLevelJSONKeys(from: propertiesBody)
}

/// Returns child property keys in JSON source order, matching JavaScript `Object.entries`.
private func orderedIOSPropertyEntries(
    definitionKey: String,
    from node: Any,
    rawJSON: String
) -> [(String, SchemaNode)] {
    guard let nodeDictionary = node as? NSDictionary,
          let properties = nodeDictionary["properties"] as? NSDictionary else {
        return []
    }

    let orderedKeys = orderedPropertyKeys(definitionKey: definitionKey, in: rawJSON)

    return orderedKeys.compactMap { key in
        guard let child = properties[key] as? SchemaNode,
              childIsAvailableOnIOS(child) else {
            return nil
        }
        return (key, child)
    }
}

private func emitNestedEnum(
    jsonKey: String,
    node: Any,
    rawJSON: String,
    indent: String
) -> [String] {
    let properties = orderedIOSPropertyEntries(
        definitionKey: jsonKey,
        from: node,
        rawJSON: rawJSON
    )
    let schemaNode = node as? SchemaNode ?? [:]

    if properties.isEmpty {
        return emitConstant(jsonKey: jsonKey, node: schemaNode, indent: indent)
    }

    var lines = emitDocumentation(for: schemaNode, indent: indent)
    lines.append("\(indent)enum \(swiftTypeName(for: jsonKey)) {")

    lines.append(contentsOf: emitConstant(jsonKey: jsonKey, node: schemaNode, indent: "\(indent)    "))
    lines.append("")

    for (index, property) in properties.enumerated() {
        lines.append(contentsOf: emitConstant(
            jsonKey: property.0,
            node: property.1,
            indent: "\(indent)    "
        ))

        if index < properties.count - 1 {
            lines.append("")
        }
    }

    lines.append("\(indent)}")

    return lines
}

private func generatePayloadParameterKeys(schema: Any, rawJSON: String, schemaVersionLabel: String) -> String {
    guard let schemaDictionary = schema as? NSDictionary,
          let defs = schemaDictionary["$defs"] as? NSDictionary else {
        return ""
    }

    let iosDefinitionKeys = defs.allKeys
        .compactMap { $0 as? String }
        .filter { key in
            guard let definition = defs[key] as? SchemaNode else {
                return false
            }
            return includesIOSSDK(definition)
        }
        .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    var topLevel: [String] = []
    var nested: [String] = []

    for jsonKey in iosDefinitionKeys {
        guard let definition = defs[jsonKey] else {
            continue
        }

        let schemaNode = definition as? SchemaNode ?? [:]
        let properties = (definition as? NSDictionary)?["properties"] as? NSDictionary
        let hasProperties = properties.map { !$0.allKeys.isEmpty } ?? false

        if hasProperties {
            nested.append(contentsOf: emitNestedEnum(
                jsonKey: jsonKey,
                node: definition,
                rawJSON: rawJSON,
                indent: "    "
            ))
            nested.append("")
        } else {
            topLevel.append(contentsOf: emitConstant(jsonKey: jsonKey, node: schemaNode, indent: "    "))
            topLevel.append("")
        }
    }

    var lines = [
        "// Generated from rakuten-analytics-json-schema \(schemaVersionLabel), \(schemaRelativePath). Do not edit manually.",
        "import Foundation",
        "",
        "/// RAT payload keys whose `x-definitionLevel` explicitly includes `iOS` and whose `x-layerLevel` is `SDK`.",
        "enum PayloadParameterKeys {",
    ]

    lines.append(contentsOf: topLevel)
    lines.append(contentsOf: nested)
    lines.append("}")
    lines.append("")

    return lines.joined(separator: "\n").replacingOccurrences(
        of: #"\n{3,}"#,
        with: "\n\n",
        options: .regularExpression
    )
}

private func downloadSchema(schemaVersion: String?) throws -> String {
    let scratchDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("rat-schema-\(UUID().uuidString)", isDirectory: true)
    let cloneDestination = scratchDirectory.appendingPathComponent("repo", isDirectory: true)

    try FileManager.default.createDirectory(at: scratchDirectory, withIntermediateDirectories: true)

    defer {
        try? FileManager.default.removeItem(at: scratchDirectory)
    }

    let credentials = try schemaRepositoryCredentials()

    var arguments = ["clone", "--depth", "1"]
    if let schemaVersion, !schemaVersion.isEmpty {
        arguments.append(contentsOf: ["--branch", schemaVersionRef(schemaVersion)])
    }
    arguments.append(schemaRepositoryCloneURL())
    arguments.append(cloneDestination.path)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = arguments

    var environment = ProcessInfo.processInfo.environment
    environment["GIT_TERMINAL_PROMPT"] = "0"

    if let credentials {
        let askpassScript = try makeAskpassScript(in: scratchDirectory)
        environment["GIT_ASKPASS"] = askpassScript.path
        environment["RAT_SCHEMA_GIT_USERNAME"] = credentials.username
        environment["RAT_SCHEMA_GIT_TOKEN"] = credentials.token
    }

    process.environment = environment

    let stderrPipe = Pipe()
    process.standardError = stderrPipe

    do {
        try process.run()
    } catch {
        throw GeneratorError.gitCloneFailed("Failed to start git clone: \(error.localizedDescription)")
    }

    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        throw GeneratorError.gitCloneFailed("git clone failed: \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    let schemaURL = cloneDestination.appendingPathComponent(schemaRelativePath)

    do {
        return try String(contentsOf: schemaURL, encoding: .utf8)
    } catch {
        throw GeneratorError.schemaReadFailed("Unable to read downloaded schema: \(error.localizedDescription)")
    }
}

private func defaultOutputPath() -> String {
    URL(fileURLWithPath: CommandLine.arguments[0])
        .standardizedFileURL
        .deletingLastPathComponent()
        .appendingPathComponent(payloadParameterKeysPath)
        .path
}

private func main() throws {
    let (schemaVersion, outputPathArgument) = try parseArguments(Array(CommandLine.arguments.dropFirst()))
    let outputPath = outputPathArgument ?? defaultOutputPath()

    let rawSchema = try downloadSchema(schemaVersion: schemaVersion)

    let schemaObject: Any
    do {
        schemaObject = try JSONSerialization.jsonObject(with: Data(rawSchema.utf8))
    } catch {
        throw GeneratorError.schemaParseFailed(
            "Unable to parse downloaded JSON schema: \(error.localizedDescription)"
        )
    }

    guard let schema = schemaObject as? NSDictionary else {
        throw GeneratorError.invalidSchema("Downloaded schema is not a JSON object")
    }

    guard let defs = schema["$defs"], !(defs is NSNull) else {
        throw GeneratorError.invalidSchema("Downloaded schema does not contain a valid $defs object")
    }

    guard defs is NSDictionary else {
        throw GeneratorError.invalidSchema("Downloaded schema does not contain a valid $defs object")
    }

    let schemaVersionLabel = schemaVersion.map(schemaVersionRef) ?? "latest"

    let swift = [
        generatePayloadParameterKeys(schema: schema, rawJSON: rawSchema, schemaVersionLabel: schemaVersionLabel),
        "enum PayloadConstants {",
        "    /// The RAT payload prefix.",
        "    static let prefix = \"cpkg_none=\"",
        "}",
        "",
    ].joined(separator: "\n")

    try swift.write(toFile: outputPath, atomically: true, encoding: .utf8)
    print("Generated \(outputPath)")
}

do {
    try main()
} catch {
    fputs("Generation failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
