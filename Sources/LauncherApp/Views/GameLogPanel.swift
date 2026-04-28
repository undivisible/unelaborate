import SwiftUI

struct GameLogPanel: View {
    @ObservedObject var viewModel: LauncherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Game Output")
                    .font(.headline)
                Spacer()
                Button("Clear") { Task { await viewModel.clearLog() } }
                Button("Close") { viewModel.showLogPanel = false }
            }

            ScrollView {
                Text(viewModel.gameLog.joined(separator: "\n"))
                    .font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 200, maxHeight: 300)
            .background(.black.opacity(0.05))
            .cornerRadius(8)
        }
    }
}
