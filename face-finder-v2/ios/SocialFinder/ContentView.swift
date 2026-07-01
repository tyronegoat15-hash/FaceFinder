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
    @State private var pulse = false
    @State private var scanPhase: CGFloat = -0.5
    @State private var particles: [Particle] = []

    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()
            if isSearching { scanningOverlay }
            VStack(spacing: 0) {
                header
                Spacer()
                if let img = selectedImage { imagePreview(img) }
                else { emptyState }
                Spacer()
                bottomBar.padding(.bottom, 35)
            }
        }
        .sheet(isPresented: $showCamera) { CameraView(image: $selectedImage) }
        .sheet(isPresented: $showPicker) { ImagePicker(image: $selectedImage) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(isPresented: $showResults) {
            if let r = result { ResultsView(result: r) { reset() } }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: { Text(errorMsg ?? "Unknown error") }
        .onAppear { checkBackend(); generateParticles() }
    }

    private var bgGradient: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.05, green: 0.02, blue: 0.15),
                Color(red: 0.15, green: 0.02, blue: 0.25),
                Color(red: 0.02, green: 0.06, blue: 0.18),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)

            ForEach(particles) { p in
                Circle().fill(p.color.opacity(0.15))
                    .frame(width: p.size, height: p.size)
                    .position(p.position)
                    .animation(.easeInOut(duration: p.duration).repeatForever(autoreverses: true), value: pulse)
            }
        }
    }

    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle().stroke(.purple.opacity(0.3), lineWidth: 2).frame(width: 160, height: 160)
                    Circle().stroke(.purple.opacity(0.5), lineWidth: 2).frame(width: 120, height: 120)
                    Circle().stroke(.purple.opacity(0.7), lineWidth: 2).frame(width: 80, height: 80)
                    Circle().fill(.purple.opacity(0.15)).frame(width: 40, height: 40)
                        .overlay(Image(systemName: "faceid").font(.title2).foregroundColor(.white))

                    RadarArc()
                        .stroke(LinearGradient(colors: [.clear, .purple, .blue], startPoint: .leading, endPoint: .trailing),
                                style: StrokeStyle(lineWidth: 3, dash: [4, 12]))
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(Double(scanPhase * 360)))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: scanPhase)
                }

                VStack(spacing: 6) {
                    Text("Scanning the web...").font(.title3.weight(.bold)).foregroundColor(.white)
                    Text("Yandex + Google + Criminal databases")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .onAppear { scanPhase = 1 }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FaceFinder").font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Instant OSINT by face").font(.caption).foregroundColor(.white.opacity(0.4))
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
        .padding(.horizontal, 20).padding(.top, 56).padding(.bottom, 8)
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
            Text("Take or choose a photo").font(.title2.weight(.bold)).foregroundColor(.white)
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

    private var bottomBar: some View {
        HStack(spacing: 12) {
            btn("camera.fill", "Camera", .blue) { showCamera = true }
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

    private func generateParticles() {
        for _ in 0..<15 {
            particles.append(Particle(
                position: CGPoint(x: CGFloat.random(in: 0...400), y: CGFloat.random(in: 0...800)),
                color: [Color.purple, .blue, .pink, .indigo].randomElement()!,
                size: CGFloat.random(in: 2...6),
                duration: Double.random(in: 3...7)
            ))
        }
        DispatchQueue.main.async { withAnimation(.easeInOut(duration: 2).repeatForever()) { pulse.toggle() } }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let size: CGFloat
    let duration: Double
}

struct RadarArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        return p
    }
}
