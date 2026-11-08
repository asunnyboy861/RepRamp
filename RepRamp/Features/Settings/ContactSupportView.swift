import SwiftUI

struct SupportSubject: Identifiable, Hashable {
    let title: String
    let icon: String
    var id: String { title }
}

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = "General"
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var banner: Banner?

    private let subjects: [SupportSubject] = [
        SupportSubject(title: "General", icon: "bubble.left.fill"),
        SupportSubject(title: "Feature Suggestion", icon: "lightbulb.fill"),
        SupportSubject(title: "Bug Report", icon: "ant.fill"),
        SupportSubject(title: "Usage Question", icon: "questionmark.circle.fill"),
        SupportSubject(title: "Performance Issue", icon: "gauge.with.dots.needle.67percent"),
        SupportSubject(title: "UI Improvement", icon: "paintpalette.fill")
    ]

    private var otherSubject = SupportSubject(title: "Other", icon: "ellipsis.circle.fill")

    private var effectiveSubject: String {
        subject == "Other" ? customSubject.trimmingCharacters(in: .whitespacesAndNewlines) : subject
    }

    private var emailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains("."), trimmed.count >= 5 else { return false }
        return true
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        emailValid &&
        !effectiveSubject.isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSending
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                subjectSection
                fieldsSection
                submitSection
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Close") { dismiss() }
                    .foregroundStyle(Theme.orange)
            }
        }
        .onChange(of: message) { _, newValue in
            if newValue.count > 1000 {
                message = String(newValue.prefix(1000))
            }
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What is this about?")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(subjects) { item in
                    subjectTile(item)
                }
            }
            subjectTile(otherSubject)
            if subject == "Other" {
                TextField("Tell us the topic", text: $customSubject)
                    .padding(12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private func subjectTile(_ item: SupportSubject) -> some View {
        let selected = subject == item.title
        return Button {
            subject = item.title
            if item.title != "Other" { customSubject = "" }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundStyle(selected ? Color.white : Theme.textSecondary)
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selected ? Color.white : Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(selected ? Theme.orange : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Theme.orange : Theme.separator, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.white)
                        .font(.caption)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldLabel("Your name")
            TextField("Your name", text: $name)
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(Theme.textPrimary)

            fieldLabel("Email")
            TextField("yourname@example.com", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(Theme.textPrimary)
            if !email.isEmpty && !emailValid {
                Text("Enter a valid email address.")
                    .font(.caption2)
                    .foregroundStyle(Theme.warning)
            }

            fieldLabel("Message")
            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text("Tell us what's on your mind...")
                        .font(.body)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(16)
                }
                TextEditor(text: $message)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(10)
                    .foregroundStyle(Theme.textPrimary)
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            HStack {
                Spacer()
                Text("\(message.count) / 1000")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .cardStyle(padding: 16)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.textSecondary)
    }

    private var submitSection: some View {
        VStack(spacing: 10) {
            if let banner {
                Text(banner.message)
                    .font(.caption)
                    .foregroundStyle(banner.isSuccess ? Theme.success : Theme.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle(padding: 12)
            }
            Button {
                Task { await send() }
            } label: {
                HStack {
                    if isSending { ProgressView().tint(.white) }
                    Text(isSending ? "Sending..." : "Submit")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1.0 : 0.45)

            Text("We only use your email to respond to this feedback.")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func send() async {
        isSending = true
        banner = nil
        let request = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            subject: effectiveSubject,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            app_name: "RepRamp"
        )
        do {
            try await ContactSupportService.submit(request)
            banner = Banner(message: "Thank you! Your feedback has been sent.", isSuccess: true)
            message = ""
        } catch {
            banner = Banner(message: error.localizedDescription, isSuccess: false)
        }
        isSending = false
    }
}

struct Banner {
    let message: String
    let isSuccess: Bool
}
