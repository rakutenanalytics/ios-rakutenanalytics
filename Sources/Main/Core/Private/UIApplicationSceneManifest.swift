import Foundation

/// Application Scene Manifest Model
struct ApplicationSceneManifest: Decodable {
    enum CodingKeys: String, CodingKey {
        case applicationSupportsMultipleScenes = "UIApplicationSupportsMultipleScenes"
        case sceneConfigurations = "UISceneConfigurations"
    }

    var applicationSupportsMultipleScenes: Bool?
    var sceneConfigurations: SceneConfigurations?
}

/// Scene Configurations Model
struct SceneConfigurations: Decodable {
    enum CodingKeys: String, CodingKey {
        case windowSceneSessionRoleApplication = "UIWindowSceneSessionRoleApplication"
    }

    var windowSceneSessionRoleApplication: [SceneConfiguration]?
}

/// Scene Configuration Model
struct SceneConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case sceneDelegateClassName = "UISceneDelegateClassName"
    }

    var sceneDelegateClassName: String?
}
