import Foundation

enum Speaker: Codable, Equatable, Hashable {
    case jasonTodd
    case mattMurdock
    case judgeJerry
    case deadpool
    case guest(id: String, name: String)

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
}

enum FixedRole: String, Codable, Equatable {
    case plaintiffLawyer
    case defenseLawyer
    case judge
    case announcer
}
