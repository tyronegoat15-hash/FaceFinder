import SwiftUI

struct ResultsView: View {
    let result: SearchResponse
    var onReset: () -> Void

    @State private var selectedTab = 0
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Results").font(.title.bold()).foregroundColor(.white)
                    Spacer()
                    Text("\(result.totalMatches) matches").font(.caption).foregroundColor(.white.opacity(0.4))
                    Button(action: onReset) {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20).padding(.top, 56).padding(.bottom, 8)

                // Stats bar
                HStack(spacing: 0) {
                    stat("\(result.socialProfiles.count)", "Social", .green)
                    Divider().frame(height: 24).background(.white.opacity(0.08))
                    stat("\(result.criminalRecords.count)", "Records", .red)
                    Divider().frame(height: 24).background(.white.opacity(0.08))
                    stat("\(result.otherMatches.count)", "Web", .blue)
                    Divider().frame(height: 24).background(.white.opacity(0.08))
                    stat("\(result.totalMatches)", "Total", .orange)
                }
                .padding(12).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20).padding(.bottom, 12)

                // Tabs
                HStack(spacing: 0) {
                    tabBtn("Social", icon: "person.2.fill", tab: 0)
                    tabBtn("Criminal", icon: "exclamationmark.shield.fill", tab: 1)
                    tabBtn("Web", icon: "globe", tab: 2)
                }
                .padding(.horizontal, 20).padding(.bottom, 8)

                // Content
                TabView(selection: $selectedTab) {
                    socialTab.tag(0)
                    criminalTab.tag(1)
                    webTab.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onAppear { animate = true }
    }

    private func stat(_ count: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(count).font(.title3.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private func tabBtn(_ label: String, icon: String, tab: Int) -> some View {
        Button {
            withAnimation(.spring) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.footnote)
                Text(label).font(.caption2.weight(.semibold))
            }
            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.3))
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .background(selectedTab == tab ? .white.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // === SOCIAL TAB ===
    private var socialTab: some View {
        ScrollView {
            if result.socialProfiles.isEmpty {
                emptyTab("No social profiles found", "person.slash")
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(Array(result.socialProfiles.enumerated()), id: \.element.id) { i, p in
                        socialRow(p).offset(y: animate ? 0 : 20).opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.85).delay(Double(i) * 0.04), value: animate)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
    }

    private func socialRow(_ p: SocialProfile) -> some View {
        Link(destination: p.platformURL ?? URL(string: "https://\(p.platform.lowercased())")!) {
            HStack(spacing: 12) {
                Circle().fill(Color(hex: p.color).opacity(0.2)).frame(width: 40, height: 40)
                    .overlay(Image(systemName: sfIcon(p.platform)).foregroundColor(Color(hex: p.color)).font(.footnote))

                VStack(alignment: .leading, spacing: 1) {
                    Text(p.platform).font(.subheadline.weight(.semibold)).foregroundColor(.white)
                    if let u = p.username { Text(u).font(.caption).foregroundColor(.white.opacity(0.4)) }
                    else { Text("Profile found").font(.caption).foregroundColor(.white.opacity(0.3)) }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(p.confidenceLabel).font(.caption2.weight(.bold)).foregroundColor(p.confidenceColor)
                    Text("\(p.confidence)%").font(.caption2).foregroundColor(.white.opacity(0.3))
                }

                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.2))
            }
            .padding(12).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // === CRIMINAL TAB ===
    private var criminalTab: some View {
        ScrollView {
            if result.criminalRecords.isEmpty {
                emptyTab("No criminal records found", "checkmark.shield")
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(result.criminalRecords) { r in
                        Link(destination: URL(string: r.url)!) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(r.color).font(.title3)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(r.type).font(.subheadline.weight(.semibold)).foregroundColor(.white)
                                    Text(r.source).font(.caption).foregroundColor(.white.opacity(0.4))
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.2))
                            }
                            .padding(12).background(r.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(r.color.opacity(0.2), lineWidth: 0.5))
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
    }

    // === WEB TAB ===
    private var webTab: some View {
        ScrollView {
            if result.otherMatches.isEmpty {
                emptyTab("No web matches", "globe")
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(result.otherMatches) { m in
                        Link(destination: URL(string: m.url)!) {
                            HStack {
                                Image(systemName: "link").font(.caption).foregroundColor(.white.opacity(0.3))
                                Text(m.url).font(.caption).lineLimit(1).foregroundColor(.white.opacity(0.5))
                                Spacer()
                                Text("\(m.confidence)%").font(.caption2).foregroundColor(.white.opacity(0.3))
                            }
                            .padding(10).background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
    }

    private func emptyTab(_ msg: String, _ icon: String) -> some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 80)
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(.white.opacity(0.15))
            Text(msg).font(.headline).foregroundColor(.white.opacity(0.4))
        }
    }

    private func sfIcon(_ platform: String) -> String {
        let p = platform.lowercased()
        if p.contains("instagram") { return "camera.viewfinder" }
        if p.contains("tiktok") { return "music.note" }
        if p.contains("facebook") { return "f.square" }
        if p.contains("twitter") || p.contains("x ") { return "bird" }
        if p.contains("snapchat") { return "ghost" }
        if p.contains("linkedin") { return "link" }
        if p.contains("youtube") { return "play.rectangle" }
        if p.contains("reddit") { return "bubble.left" }
        if p.contains("pinterest") { return "pin" }
        if p.contains("github") { return "chevron.left.forwardslash.chevron.right" }
        if p.contains("onlyfans") { return "lock" }
        if p.contains("discord") { return "bubble.left.and.bubble.right" }
        if p.contains("telegram") { return "paperplane" }
        if p.contains("twitch") { return "tv" }
        if p.contains("patreon") { return "heart" }
        if p.contains("threads") { return "at" }
        return "person.circle"
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if let i = Int(h, radix: 16) {
            self.init(
                red: Double((i >> 16) & 0xFF) / 255,
                green: Double((i >> 8) & 0xFF) / 255,
                blue: Double(i & 0xFF) / 255
            )
        } else { self = .gray }
    }
}

#Preview {
    ResultsView(result: SearchResponse(
        success: true, totalMatches: 10,
        socialProfiles: [SocialProfile(platform: "Instagram", icon: "camera.viewfinder", color: "#E4405F", url: "https://instagram.com/user", username: "@user", confidence: 91)],
        criminalRecords: [CriminalRecord(source: "Mugshots.com", type: "Mugshot", url: "https://mugshots.com/123", confidence: 55)],
        otherMatches: [OtherMatch(url: "https://example.com", confidence: 40)]
    ), onReset: {})
}
