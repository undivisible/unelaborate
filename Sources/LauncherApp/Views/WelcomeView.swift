import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: LauncherViewModel
    @State private var offlineUsername = ""
    @State private var showOfflineForm = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.secondary)

                VStack(spacing: 6) {
                    Text("unelaborate")
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                    Text("Minecraft for Mac")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Spacer()

            VStack(spacing: 12) {
                WelcomeButton(title: "Sign in with Microsoft", icon: "person.badge.key.fill", style: .primary) {
                    Task { await viewModel.beginMicrosoftLogin() }
                }

                WelcomeButton(title: "Play Offline", icon: "person.fill", style: .secondary) {
                    withAnimation(.easeInOut(duration: 0.2)) { showOfflineForm.toggle() }
                }

                if showOfflineForm {
                    VStack(spacing: 16) {
                        TextField("Username", text: $offlineUsername)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 260)
                            .padding(.vertical, 8)

                        WelcomeButton(
                            title: "Continue",
                            icon: "arrow.right",
                            style: .primary,
                            disabled: offlineUsername.trimmingCharacters(in: .whitespaces).isEmpty
                        ) {
                            Task { await viewModel.loginOffline(username: offlineUsername) }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if !viewModel.authCodeMessage.isEmpty {
                    Text(viewModel.authCodeMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                        .padding(.top, 4)
                }
            }

            Spacer()

            Text("MPL-2.0  ·  macOS 14+")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 24)
        }
        .frame(minWidth: 600, minHeight: 520)
        .background(.windowBackground)
    }
}

struct WelcomeButton: View {
    enum Style { case primary, secondary }

    let title: String
    let icon: String
    let style: Style
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: 300)
            .padding(.vertical, 13)
            .background(background)
            .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: 12).fill(Color.accentColor)
        case .secondary:
            RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
        }
    }

    private var foreground: some ShapeStyle {
        switch style {
        case .primary: return AnyShapeStyle(.white)
        case .secondary: return AnyShapeStyle(.primary)
        }
    }
}
