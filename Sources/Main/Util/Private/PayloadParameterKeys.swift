import Foundation

enum PayloadParameterKeys {
    static let acc = "acc"
    static let aid = "aid"
    static let etype = "etype"
    static let cp = "cp"
    static let pgn = "pgn"
    static let ref = "ref"

    enum Core {
        static let appVer = "app_ver"
        static let appName = "app_name"
        static let mos = "mos"
        static let ver = "ver"
        static let ts1 = "ts1"
    }

    enum Identifier {
        static let ckp = "ckp"
        static let cks = "cks"
        static let cka = "cka"
        static let userid = "userid"
        static let easyid = "easyid"
    }

    enum Language {
        static let dln = "dln"
    }

    enum Device {
        static let powerStatus = "powerstatus"
        static let mbat = "mbat"
        static let model = "model"
        static let res = "res"
    }

    enum Location {
        static let accu = "accu"
        static let altitude = "altitude"
        static let tms = "tms"
        static let lat = "lat"
        static let long = "long"
        static let speed = "speed"
        static let loc = "loc"
    }

    enum Orientation {
        static let mori = "mori"
    }

    enum Network {
        static let online = "online"
    }

    enum UserAgent {
        static let ua = "ua"
    }

    enum Time {
        static let ltm = "ltm"
    }

    enum TimeZone {
        static let tzo = "tzo"
    }

    enum Telephony {
        static let mcn = "mcn"
        static let mcnd = "mcnd"
        static let mnetw = "mnetw"
        static let mnetwd = "mnetwd"
    }
}

enum CpParameterKeys {
    enum Ref {
        static let type = "ref_type"
        static let accountIdentifier = "ref_acc"
        static let applicationIdentifier = "ref_aid"
        static let link = "ref_link"
        static let component = "ref_comp"
    }

    enum SessionStart {
        static let daysSinceFirstUse = "days_since_first_use"
        static let daysSinceLastUse = "days_since_last_use"
    }

    enum Page {
        static let title = "title"
        static let url = "url"
    }

    enum Push {
        static let pushNotifyValue = "push_notify_value"
        static let pushRequestIdentifier = "push_request_id"
        static let pushConversionAction = "push_cv_action"
    }

    enum PNP {
        static let deviceId = "deviceId"
        static let pnpClientId = "pnpClientId"
    }

    enum Login {
        static let method = "login_method"
    }

    enum Logout {
        static let method = "logout_method"
    }
}

enum PayloadConstants {
    static let prefix = "cpkg_none="
}
