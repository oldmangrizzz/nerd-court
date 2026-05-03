import SwiftUI

struct IntakeScreen: View {
    @State private var plaintiff = ""
    @State private var defendant = ""
    @State private var grievanceText = ""
    @State private var selectedFranchise: Franchise? = .dc
    @State private var isSubmitting = false
    @State private var rateLimitMessage: String?
    private let rateLimiter = SubmissionRateLimiter()
    @Environment(AppState.self) private var appState: AppState

    var body: some View {
        ZStack {
            cinematicBackground

            VStack(spacing: 24) {
                headerView

                VStack(spacing: 16) {
                    grievanceField(label: "Plaintiff", placeholder: "e.g. Luke Skywalker", text: $plaintiff)
                    vsDivider
                    grievanceField(label: "Defendant", placeholder: "e.g. Rey Palpatine", text: $defendant)
                    grievanceField(label: "Grievance", placeholder: "What canon crime was committed and why it matters...",
                                   text: $grievanceText, lineLimit: 5)

                    franchiseSelector
                }
                .padding(.horizontal, 24)

                submitButton

                if let rateLimitMessage {
                    Text(rateLimitMessage)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier("rateLimitMessage")
                }
                
                Button {
                    appState.activeGrievance = Grievance(
                        id: UUID().uuidString,
                        plaintiff: "Test",
                        defendant: "Test",
                        grievanceText: "Quick start test grievance.",
                        franchise: selectedFranchise ?? .dc
                    )
                    appState.currentDebatePhase = .canonResearch
                } label: {
                    Text("QUICK START")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow.opacity(0.6))
                }
                .accessibilityIdentifier("quickStartTrialButton")
            }
        }
    }

    private var franchiseSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FRANCHISE")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow.opacity(0.8))
            FranchiseTagSelector(selectedFranchise: $selectedFranchise)
        }
    }

    private var cinematicBackground: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo.opacity(0.4), .purple.opacity(0.2), .black],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack {
                ForEach(0..<6) { i in
                    Rectangle()
                        .fill(.white.opacity(0.03))
                        .frame(height: 1)
                        .offset(y: CGFloat(i * 80))
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("NERD COURT")
                .font(.system(size: 42, weight: .black, design: .serif))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange, .red],
                                                startPoint: .leading, endPoint: .trailing))
            Text("True Canon is Law")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 60)
    }

    private var vsDivider: some View {
        HStack(spacing: 8) {
            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
            Text("VS")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
        }
    }

    private func grievanceField(label: String, placeholder: String, text: Binding<String>,
                                 lineLimit: Int = 3) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow.opacity(0.8))
            TextField(placeholder, text: text, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(lineLimit...lineLimit)
                .padding(12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.15), lineWidth: 1))
                .foregroundColor(.white)
                .tint(.yellow)
        }
    }

    private var submitButton: some View {
        Button {
            submitGrievance()
        } label: {
            HStack {
                Image(systemName: "hammer.fill")
                Text("FILE GRIEVANCE")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(isFormValid ? Color.yellow : Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isFormValid || isSubmitting)
        .padding(.top, 12)
    }

    private var isFormValid: Bool {
        !InputSanitizer.sanitize(plaintiff, field: .party).isEmpty &&
        !InputSanitizer.sanitize(defendant, field: .party).isEmpty &&
        !InputSanitizer.sanitize(grievanceText, field: .grievance).isEmpty
    }

    private func submitGrievance() {
        isSubmitting = true
        let safePlaintiff = InputSanitizer.sanitize(plaintiff, field: .party)
        let safeDefendant = InputSanitizer.sanitize(defendant, field: .party)
        let safeGrievance = InputSanitizer.sanitize(grievanceText, field: .grievance)
        guard !safePlaintiff.isEmpty, !safeDefendant.isEmpty, !safeGrievance.isEmpty else {
            isSubmitting = false
            return
        }
        let decision = rateLimiter.consume()
        guard decision.allowed else {
            rateLimitMessage = decision.humanReason
            isSubmitting = false
            return
        }
        rateLimitMessage = nil
        let grievance = Grievance(
            id: UUID().uuidString,
            plaintiff: safePlaintiff,
            defendant: safeDefendant,
            grievanceText: safeGrievance,
            franchise: selectedFranchise ?? .dc
        )
        appState.activeGrievance = grievance
        appState.currentDebatePhase = .canonResearch
        // Dismiss keyboard and switch to Courtroom tab so the trial is visible
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        appState.selectedTab = 1
        isSubmitting = false
    }
}
