import Foundation

enum FinisherType: String, Codable {
    case crowbarBeatdown
    case lazarusPitDunking
    case deadpoolShooting
    case characterMorph
    case gavelOfDoom

    var label: String {
        switch self {
        case .crowbarBeatdown: "Crowbar Beatdown"
        case .lazarusPitDunking: "Lazarus Pit Dunking"
        case .deadpoolShooting: "Deadpool Bullet Ballet"
        case .characterMorph: "Morph-and-Smash"
        case .gavelOfDoom: "Gavel of Doom"
        }
    }
}
