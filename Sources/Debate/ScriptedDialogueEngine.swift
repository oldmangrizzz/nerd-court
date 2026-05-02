import Foundation

/// Real dialogue engine. No LLM, no network, no mocks.
/// Generates character-accurate scripted arguments based on case context.
enum ScriptedDialogueEngine {

    static func openingStatement(plaintiff: String, defendant: String, grievance: String, speaker: Speaker) -> String {
        switch speaker {
        case .jasonTodd:
            return jasonOpening(plaintiff: plaintiff, defendant: defendant, grievance: grievance)
        case .mattMurdock:
            return mattOpening(plaintiff: plaintiff, defendant: defendant, grievance: grievance)
        default:
            return "The court is now in session."
        }
    }

    static func closingArgument(plaintiff: String, defendant: String, grievance: String, evidence: [String], speaker: Speaker) -> String {
        switch speaker {
        case .jasonTodd:
            return jasonClosing(plaintiff: plaintiff, defendant: defendant, grievance: grievance, evidence: evidence)
        case .mattMurdock:
            return mattClosing(plaintiff: plaintiff, defendant: defendant, grievance: grievance, evidence: evidence)
        default:
            return "Closing arguments heard."
        }
    }

    static func verdictIntro(plaintiff: String, defendant: String) -> String {
        "Ladies and gentle-nerds! After much dramatic tension, fabricated evidence, and at least three objections that were completely ignored... the moment you've all been waiting for!"
    }

    static func deadpoolWrap(plaintiff: String, defendant: String, verdict: String) -> String {
        "That's a wrap on Nerd Court! \(verdict) in the case of \(plaintiff) versus \(defendant). Remember: if you can't settle it in canon, settle it in court. Take care of yourselves and each other. I'm Deadpool, and this has been... disturbingly educational."
    }

    static func judgeVerdict(plaintiff: String, defendant: String, grievance: String, plaintiffEvidence: [String], defendantEvidence: [String]) -> Verdict {
        let pWeight = plaintiffEvidence.count
        let dWeight = defendantEvidence.count
        let ruling: Verdict.Ruling
        let reasoning: String
        let wisdom: String
        let finisher: FinisherType?

        if pWeight > dWeight {
            ruling = .plaintiffWins
            reasoning = "The plaintiff demonstrated that \(defendant)'s actions constitute a clear violation of established canon."
            wisdom = "Canon is not a suggestion. It is the foundation upon which every great story stands."
            finisher = .gavelOfDoom
        } else if dWeight > pWeight {
            ruling = .defendantWins
            reasoning = "The defense successfully argued that narrative evolution does not equal canon betrayal."
            wisdom = "A story must be allowed to breathe, to grow, to surprise even its creators."
            finisher = .characterMorph
        } else {
            ruling = .hugItOut
            reasoning = "Both sides presented compelling arguments about the nature of canon and storytelling."
            wisdom = "When canon divides us, our shared love of the story must unite us."
            finisher = nil
        }

        return Verdict(
            ruling: ruling,
            reasoning: reasoning,
            punishmentOrReward: "Both parties are sentenced to re-read the source material together.",
            judgeJerryWisdom: wisdom,
            finisher: finisher
        )
    }

    static func crossExamination(guestName: String, attacker: Speaker) -> String {
        if attacker == .mattMurdock {
            return "Isn't it true, \(guestName), that your testimony relies on fan interpretation rather than primary source material?"
        }
        return "One simple question, \(guestName): did you even read the original comics before forming this opinion?"
    }

    static func witnessTestimony(guestName: String, universe: String, role: String) -> String {
        "I am \(guestName) from \(universe), serving as \(role). In my professional and fictional opinion, the canon speaks for itself. The rest is just noise from people who haven't done their homework."
    }

    static func genericPhase(phaseName: String, plaintiff: String, defendant: String) -> String {
        "Proceeding to \(phaseName.lowercased()) in the matter of \(plaintiff) versus \(defendant)."
    }

    // MARK: — Jason Todd (plaintiff's counsel)

    private static func jasonOpening(plaintiff: String, defendant: String, grievance: String) -> String {
        "Your honor, the court has been convened because \(defendant) committed an act of narrative vandalism against \(plaintiff). I was beaten to death with a crowbar and left in an exploding warehouse, and even *I* recognize a betrayal of canon when I see one. \(grievance.prefix(80))... The defense will try to spin this as 'creative freedom.' Don't listen. The plaintiff deserves justice, and this court is the only place left to get it."
    }

    private static func jasonClosing(plaintiff: String, defendant: String, grievance: String, evidence: [String]) -> String {
        let ev = evidence.isEmpty ? "The plaintiff's original narrative integrity" : evidence.joined(separator: "; ")
        return "Final words. \(plaintiff) built something real. Something that mattered to millions. And \(defendant) treated it like it was nothing. I know what it's like to be erased, to have your story rewritten by someone who doesn't care. Evidence: \(ev). Find for the plaintiff. Because if we don't defend canon, what the hell are we even doing here?"
    }

    // MARK: — Matt Murdock (defense counsel)

    private static func mattOpening(plaintiff: String, defendant: String, grievance: String) -> String {
        "Your honor, my client \(defendant) stands accused of nothing more than participating in the evolution of a living story. I've defended the innocent and the guilty in Hell's Kitchen for years. This? This is about whether we allow stories to grow or freeze them in amber. \(plaintiff) is a beloved character, yes. But canon is not a prison. The defense asks you to consider intent, context, and the right of creators to take risks."
    }

    private static func mattClosing(plaintiff: String, defendant: String, grievance: String, evidence: [String]) -> String {
        let ev = evidence.isEmpty ? "The defendant's intent to evolve rather than destroy" : evidence.joined(separator: "; ")
        return "In closing. I lost my sight and I gained clarity. Sometimes what looks like destruction is actually creation wearing a mask. \(defendant) did not hate \(plaintiff). They believed in the story enough to challenge it. Evidence: \(ev). I ask this court to rule that canon is a conversation, not a commandment. Find for the defense."
    }
}

// MARK: — Phase dialogue generator

extension ScriptedDialogueEngine {
    static func dialogueForPhase(_ phase: DebatePhase, grievance: Grievance, research: CanonResearchResult, guests: [GuestCharacter]) -> [SpeechTurn] {
        let p = grievance.plaintiff
        let d = grievance.defendant
        let g = grievance.grievanceText

        switch phase {
        case .openingStatement:
            return [
                SpeechTurn(speaker: .jasonTodd, text: openingStatement(plaintiff: p, defendant: d, grievance: g, speaker: .jasonTodd), phase: "opening_statement"),
                SpeechTurn(speaker: .mattMurdock, text: openingStatement(plaintiff: p, defendant: d, grievance: g, speaker: .mattMurdock), phase: "opening_statement"),
            ]
        case .witnessTestimony:
            return guests.map { guest in
                SpeechTurn(speaker: guest.speaker,
                           text: witnessTestimony(guestName: guest.name, universe: guest.universe, role: guest.role),
                           phase: "witness_testimony")
            }
        case .crossExamination:
            let attacker: Speaker = guests.first?.role == "plaintiff_witness" ? .mattMurdock : .jasonTodd
            return [
                SpeechTurn(speaker: attacker,
                           text: crossExamination(guestName: guests.first?.name ?? "the witness", attacker: attacker),
                           phase: "cross_examination")
            ]
        case .closingArguments:
            return [
                SpeechTurn(speaker: .jasonTodd, text: closingArgument(plaintiff: p, defendant: d, grievance: g, evidence: research.plaintiffEvidence, speaker: .jasonTodd), phase: "closing_arguments"),
                SpeechTurn(speaker: .mattMurdock, text: closingArgument(plaintiff: p, defendant: d, grievance: g, evidence: research.defendantEvidence, speaker: .mattMurdock), phase: "closing_arguments"),
            ]
        case .verdictAnnouncement:
            return [
                SpeechTurn(speaker: .deadpool, text: verdictIntro(plaintiff: p, defendant: d), phase: "verdict_announcement")
            ]
        case .finisherExecution:
            return [
                SpeechTurn(speaker: .judgeJerry, text: "The court hereby delivers its final judgment!", phase: "finisher_execution")
            ]
        case .postTrialCommentary:
            return [
                SpeechTurn(speaker: .judgeJerry, text: "I've seen a lot of cases in my time. This one... this one actually made me think.", phase: "post_trial_commentary")
            ]
        case .deadpoolWrapUp:
            return [
                SpeechTurn(speaker: .deadpool, text: deadpoolWrap(plaintiff: p, defendant: d, verdict: "Justice served"), phase: "deadpool_wrap")
            ]
        default:
            return [SpeechTurn(speaker: .judgeJerry, text: genericPhase(phaseName: phase.displayName, plaintiff: p, defendant: d), phase: phase.rawValue)]
        }
    }
}
