import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = FaceSearchService.shared
    @State private var url = ""
    @State private var healthStatus: String?
    @State private var healthColor: Color = .gray

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.02, blue: 0.12).ignoresSafeArea()

                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server URL").font(.headline).foregroundColor(.white)
                            TextField("http://your-server:3000", text: $url)
                                .textContentType(.URL).autocapitalization(.none).disableAutocorrection(true)
                                .keyboardType(.URL).padding(14)
                                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundColor(.white).font(.subheadline)

                            Button("Test Connection") { test() }
                                .font(.subheadline.weight(.semibold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(12)
                                .background(.purple.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))

                            if let status = healthStatus {
                                HStack {
                                    Circle().fill(healthColor).frame(width: 8, height: 8)
                                    Text(status).font(.caption).foregroundColor(healthColor)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How it works").font(.headline).foregroundColor(.white)
                            stepRow("1", "Take or upload a face photo")
                            stepRow("2", "Photo is sent to the backend server")
                            stepRow("3", "Backend searches Yandex + Google + Bing")
                            stepRow("4", "Social media profiles are extracted")
                            stepRow("5", "Criminal records are cross-referenced")
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        Text("All search engines are free. For best results, use a clear, front-facing photo with good lighting.")
                            .font(.caption2).foregroundColor(.white.opacity(0.35))
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        FaceSearchService.shared.serverURL = url
                        dismiss()
                    }.foregroundColor(.purple)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .onAppear { url = service.serverURL }
    }

    private func stepRow(_ n: String, _ t: String) -> some View {
        HStack(spacing: 10) {
            Text(n).font(.caption.bold()).foregroundColor(.white)
                .frame(width: 22, height: 22).background(Circle().fill(.purple.opacity(0.3)))
            Text(t).font(.subheadline).foregroundColor(.white.opacity(0.65))
        }
    }

    private func test() {
        healthStatus = "Testing..."
        healthColor = .gray
        FaceSearchService.shared.serverURL = url
        Task {
            if await FaceSearchService.shared.checkHealth() {
                await MainActor.run { healthStatus = "Connected!"; healthColor = .green }
            } else {
                await MainActor.run { healthStatus = "Connection failed"; healthColor = .red }
            }
        }
    }
}

#Preview { SettingsView() }
