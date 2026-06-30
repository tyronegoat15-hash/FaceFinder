import SwiftUI

struct ContentView: View {
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedImage: UIImage?
    @State private var isSearching = false
    @State private var searchResult: SearchResponse?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSettings = false
    @State private var showResults = false

    var body: some View {
        ZStack {
            gradientBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()
                if let img = selectedImage {
                    previewCard(image: img)
                } else {
                    emptyState
                }
                Spacer()
                if isSearching { searchingIndicator }
                bottomButtons
                    .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showCamera) { CameraPicker(image: $selectedImage).ignoresSafeArea() }
        .sheet(isPresented: $showPhotoLibrary) { PhotoPicker(image: $selectedImage) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(isPresented: $showResults) {
            if let result = searchResult {
                ResultsView(result: result) {
                    searchResult = nil
                    selectedImage = nil
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private var gradientBg: some View {
        LinearGradient(colors: [
            Color(red: 0.08, green: 0.04, blue: 0.18),
            Color(red: 0.18, green: 0.04, blue: 0.28),
            Color(red: 0.04, green: 0.08, blue: 0.22),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("FaceFinder")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Find anyone's social media by face")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "face.dashed")
                .font(.system(size: 72))
                .foregroundColor(.white.opacity(0.2))
            Text("Take or choose a photo")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Snap a photo to instantly find\nmatching social media profiles")
                .font(.body)
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
    }

    private func previewCard(image: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.15), lineWidth: 2))
                .shadow(color: .purple.opacity(0.3), radius: 25, y: 8)

            Text("Photo loaded")
                .font(.callout.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var searchingIndicator: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.white)
            Text("Searching across the web...")
                .font(.callout)
                .foregroundColor(.white.opacity(0.6))
            Text("Checking Yandex, Google, Bing")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.bottom, 10)
    }

    private var bottomButtons: some View {
        HStack(spacing: 14) {
            btn(icon: "camera.fill", label: "Camera", color: .blue) { showCamera = true }
            btn(icon: "photo.on.rectangle", label: "Gallery", color: .purple) { showPhotoLibrary = true }

            if selectedImage != nil {
                if !isSearching {
                    btn(icon: "magnifyingglass", label: "Search", color: .green) { search() }
                } else {
                    btn(icon: "xmark", label: "Cancel", color: .red) { }
                    .opacity(0.5)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func btn(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption2.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(color.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.4), lineWidth: 1))
        }
    }

    private func search() {
        guard let image = selectedImage else { return }
        isSearching = true
        errorMessage = nil

        Task {
            do {
                let result = try await FaceSearchService.shared.search(image: image)
                await MainActor.run {
                    searchResult = result
                    isSearching = false
                    showResults = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSearching = false
                }
            }
        }
    }
}

#Preview { ContentView() }
