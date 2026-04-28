import SwiftUI

struct ServerQuickJoinPanel: View {
    @ObservedObject var viewModel: LauncherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Join")
                .font(.headline)

            if viewModel.servers.isEmpty {
                Text("Add servers in Settings")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.servers) { server in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(server.name).font(.subheadline.weight(.semibold))
                            Text("\(server.address):\(server.port)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Join") {
                            Task { await viewModel.launchWithServer(server) }
                        }
                    }
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
