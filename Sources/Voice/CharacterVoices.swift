import Foundation

enum CharacterVoiceID: String {
    case jasonTodd = "jason_todd_red_hood_v1"
    case mattMurdock = "matt_murdock_daredevil_v1"
    case judgeJerry = "judge_jerry_springer_v1"
    case deadpoolNPH = "deadpool_nph_v1"

    var sourceMaterial: String {
        switch self {
        case .jasonTodd: "YouTube: Under the Red Hood (2010), Arkham Knight game dialogue"
        case .mattMurdock: "YouTube: Daredevil Netflix series (2015-2018) courtroom scenes"
        case .judgeJerry: "YouTube: Jerry Springer Show archive clips, final-thought segments"
        case .deadpoolNPH: "YouTube: Doctor Who 60th Anniversary — The Giggle, NPH interviews"
        }
    }

    static func forSpeaker(_ speaker: Speaker) -> CharacterVoiceID {
        switch speaker {
        case .jasonTodd: .jasonTodd
        case .mattMurdock: .mattMurdock
        case .judgeJerry: .judgeJerry
        case .deadpool: .deadpoolNPH
        case .guest: .jasonTodd  // guests routed to custom voice gen
        }
    }
}
