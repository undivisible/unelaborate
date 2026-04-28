import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var viewModel: LauncherViewModel
    @State private var showCreate = false
    @State private var showImport = false
    @State private var showCFImport = false

    var body: some View {
        NavigationSplitView {
            InstanceSidebar(viewModel: viewModel, showCreate: $showCreate)
        } detail: {
            if let instance = viewModel.selectedInstance {
                MainDashboard(viewModel: viewModel, instance: instance)
            } else {
                EmptyStateView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("New Instance") { showCreate = true }
                    Divider()
                    Button("Import .mrpack…") { showImport = true }
                    Button("Import CurseForge Zip…") { showCFImport = true }
                } label: {
                    Image(systemName: "plus")
                } primaryAction: {
                    showCreate = true
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateInstanceSheet(viewModel: viewModel)
        }
        .fileImporter(isPresented: $showImport, allowedContentTypes: [.init(filenameExtension: "mrpack")!]) { result in
            if case let .success(url) = result {
                Task { await viewModel.importMrpack(from: url) }
            }
        }
        .fileImporter(isPresented: $showCFImport, allowedContentTypes: [.zip]) { result in
            if case let .success(url) = result {
                Task { await viewModel.importCurseForgeZip(from: url) }
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No instance selected")
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Create a new instance to get started")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }
}
