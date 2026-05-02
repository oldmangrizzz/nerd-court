import Foundation

enum Speaker: Codable, Equatable, Hashable {
    case jasonTodd
    case mattMurdock
    case judgeJerry
    case deadpool
    case guest(id: String, name: String)
    
    var rawValue: String {
        switch self {
        case .jasonTodd: return "jasonTodd"
        case .mattMurdock: return "mattMurdock"
        case .judgeJerry: return "judgeJerry"
        case .deadpool: return "deadpool"
        case .guest(let id, _): return "guest_\(id)"
        }
    }

    var displayName: String {
        switch self {
        case .jasonTodd: "Jason Todd"
        case .mattMurdock: "Matt Murdock"
        case .judgeJerry: "Judge Jerry Springer"
        case .deadpool: "Deadpool"
        case .guest(_, let name): name
        }
    }

    var roleLabel: String {
        switch self {
        case .jasonTodd: "Plaintiff's Counsel"
        case .mattMurdock: "Defense Counsel"
        case .judgeJerry: "Presiding Judge"
        case .deadpool: "Court Announcer"
        case .guest: "Witness"
        }
    }

    var avatarID: String {
        switch self {
        case .jasonTodd: "avatar_jason"
        case .mattMurdock: "avatar_matt"
        case .judgeJerry: "avatar_jerry"
        case .deadpool: "avatar_deadpool"
        case .guest(_, let name): "avatar_\(name.replacingOccurrences(of: " ", with: "_"))"
        }
    }
}

enum FixedRole: String, Codable, Equatable {
    case plaintiffLawyer
    case defenseLawyer
    case judge
    case announcer
}
