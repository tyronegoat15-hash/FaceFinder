import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var serverURL: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.04, blue: 0.15).ignoresSafeArea()

                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Server URL")
                                .font(.headline)
                                .foregroundColor(.white)

                            TextField("http://your-server.com:3000", text: $serverURL)
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.URL)
                                .padding()
                                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundColor(.white)

                            Text("Enter the URL of your backend server.\nDefault: http://localhost:3000")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How it works")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 12) {
                                settingRow("1", "Take or upload a photo")
                                settingRow("2", "Photo is sent to the backend server")
                                settingRow("3", "Backend searches Yandex, Google & Bing")
                                settingRow("4", "Results are filtered for social profiles")
                                settingRow("5", "Tap any result to open the profile")
                            }
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Engines")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack {
                                engineBadge("Yandex", color: .red)
                                engineBadge("Google", color: .blue)
                                engineBadge("Bing", color: .green)
                            }
                        }
                        .listRowBackground(Color.clear)

                        Text("All search engines are free — no API keys required")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.35))
                            .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        FaceSearchService.shared.updateServerURL(serverURL)
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .onAppear {
            serverURL = FaceSearchService.shared.getServerURL()
        }
    }

    private func settingRow(_ num: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(num)
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(.purple.opacity(0.3)))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func engineBadge(_ name: String, color: Color) -> some View {
        Text(name)
            .font(.caption2.bold())
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 0.5))
    }
}

#Preview { SettingsView() }
