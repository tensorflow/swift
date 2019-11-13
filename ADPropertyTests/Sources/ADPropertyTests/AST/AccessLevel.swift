/// Declaration access level.
enum AccessLevel: Int, CustomStringConvertible, CaseIterable, Comparable {
    case alPrivate
    case alFileprivate
    case alInternal
    case alPublic

    var description: String {
        switch self {
        case .alPrivate:
            return "private"
        case .alFileprivate:
            return "fileprivate"
        case .alInternal:
            return "internal"
        case .alPublic:
            return "public"
        }
    }

    static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
