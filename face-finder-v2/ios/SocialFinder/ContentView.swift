import SwiftUI

struct ContentView: View {
    @StateObject private var service = FaceSearchService.shared
    @State private var selectedImage: UIImage?
    @State private var isSearching = false
    @State private var result: SearchResponse?
    @State private var errorMsg: String?
    @State private var showError = false
    @State private var showCamera = false
    @State private var showPicker = false
    @State private var showSettings = false
    @State private var showResults = false
    @State private var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()
                if let img = selectedImage { imagePreview(img) }
                else { emptyState }
                Spacer()
                if isSearching { loadingState }
                bottomBar
                    .padding(.bottom, 35)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPicker) { ImagePicker(image: $selectedImage) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(isPresented: $showResults) {
            if let r = result { ResultsView(result: r) { reset() } }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: { Text(errorMsg ?? "Unknown error") }
        .onAppear { checkBackend() }
    }

    private var bgGradient: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.02, blue: 0.15),
            Color(red: 0.15, green: 0.02, blue: 0.25),
            Color(red: 0.02, green: 0.06, blue: 0.18),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FaceFinder")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Instant OSINT by face")
                    .font(.caption).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            HStack(spacing: 12) {
                indicator
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill").font(.title3)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 8)
    }

    private var indicator: some View {
        Circle().fill(.green).frame(width: 8, height: 8)
            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "face.dashed").font(.system(size: 70))
                .foregroundColor(.white.opacity(0.15))
            Text("Take or choose a photo")
                .font(.title2.weight(.bold)).foregroundColor(.white)
            Text("Find social media, criminal records,\nand web presence from any face")
                .font(.subheadline).foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private func imagePreview(_ img: UIImage) -> some View {
        VStack(spacing: 10) {
            Spacer()
            Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                .frame(width: 170, height: 170).clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 2))
                .shadow(color: .purple.opacity(0.3), radius: 30, y: 10)
            Text("Photo ready").font(.callout.weight(.semibold)).foregroundColor(.white.opacity(0.7))
            Spacer()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView().scaleEffect(1.6).tint(.white)
            Text("Searching the web...").font(.headline).foregroundColor(.white.opacity(0.6))
            Text("Yandex + Google + Criminal databases")
                .font(.caption2).foregroundColor(.white.opacity(0.3))
        }
        .padding(.bottom, 10)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if cameraAvailable {
                btn("camera.fill", "Camera", .blue) { showCamera = true }
            }
            btn("photo.on.rectangle", "Gallery", .purple) { showPicker = true }
            if selectedImage != nil && !isSearching {
                btn("magnifyingglass", "Search", .green) { search() }
            }
        }
        .padding(.horizontal, 16)
    }

    private func btn(_ icon: String, _ label: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption2.weight(.semibold))
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 64)
            .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.35), lineWidth: 1))
        }
    }

    private func search() {
        guard let img = selectedImage else { return }
        isSearching = true; errorMsg = nil
        Task {
            do {
                let r = try await FaceSearchService.shared.search(image: img)
                await MainActor.run { result = r; isSearching = false; showResults = true }
            } catch {
                await MainActor.run { errorMsg = error.localizedDescription; showError = true; isSearching = false }
            }
        }
    }

    private func reset() { result = nil; selectedImage = nil; isSearching = false }

    private func checkBackend() {
        Task {
            let ok = await FaceSearchService.shared.checkHealth()
            if !ok { errorMsg = "Can't reach server at\n\(service.serverURL)\n\nTap settings to configure"; showError = true }
        }
    }
}

#Preview { ContentView() }
