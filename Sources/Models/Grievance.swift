import Foundation

struct Grievance: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var plaintiff: String
    var defendant: String
    var grievanceText: String
    var franchise: Franchise
    var submittedAt: Date
    var status: GrievanceStatus
    var guestPlaintiffId: String?
    var guestDefendantId: String?

    init(id: String, plaintiff: String, defendant: String, grievanceText: String,
         franchise: Franchise = .dc,
         submittedAt: Date = .now, status: GrievanceStatus = .pending) {
        self.id = id
        self.plaintiff = plaintiff
        self.defendant = defendant
        self.grievanceText = grievanceText
        self.franchise = franchise
        self.submittedAt = submittedAt
        self.status = status
    }
}

enum GrievanceStatus: String, Codable, Equatable, Sendable {
    case pending
    case inTrial
    case decided
}
