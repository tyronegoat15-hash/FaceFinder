import SwiftUI

struct ResultsView: View {
    let result: SearchResponse
    var onReset: () -> Void

    @State private var selectedTab = 0
    @State private var cardOffsets: [CGFloat] = []
    @State private var cardOpacities: [Double] = []
    @State private var glow = false

    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                statsBar
                tabs
                content
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { glow.toggle() }
            animateCards()
        }
    }

    private var bgGradient: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.02, blue: 0.15),
            Color(red: 0.12, green: 0.02, blue: 0.22),
            Color(red: 0.02, green: 0.04, blue: 0.12),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var header: some View {
        HStack {
            Text("Results").font(.title.bold()).foregroundColor(.white)
            Spacer()
            Text("\(result.totalMatches) matches").font(.caption).foregroundColor(.white.opacity(0.4))
            Button(action: onReset) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20).padding(.top, 56).padding(.bottom, 8)
    }

    private var statsBar: some View {
        HStack(spacing: 0) {
            statItem(count: result.socialProfiles.count, label: "Social", color: .green, icon: "person.2.fill")
            Divider().frame(height: 24).background(.white.opacity(0.08))
            statItem(count: result.criminalRecords.count, label: "Records", color: .red, icon: "exclamationmark.shield.fill")
            Divider().frame(height: 24).background(.white.opacity(0.08))
            statItem(count: result.otherMatches.count, label: "Web", color: .blue, icon: "globe")
            Divider().frame(height: 24).background(.white.opacity(0.08))
            statItem(count: result.totalMatches, label: "Total", color: .orange, icon: "number")
        }
        .padding(12).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.06), lineWidth: 1))
        .padding(.horizontal, 20).padding(.bottom, 12)
    }

    private func statItem(count: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title3.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            tabBtn("Social", icon: "person.2.fill", tab: 0)
            tabBtn("Criminal", icon: "exclamationmark.shield.fill", tab: 1)
            tabBtn("Web", icon: "globe", tab: 2)
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
    }

    private func tabBtn(_ label: String, icon: String, tab: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.footnote)
                Text(label).font(.caption2.weight(.semibold))
            }
            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.3))
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .background(selectedTab == tab ? .white.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedTab == tab ? .white.opacity(0.15) : .clear, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        TabView(selection: $selectedTab) {
            socialTab.tag(0)
            criminalTab.tag(1)
            webTab.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var socialTab: some View {
        ScrollView {
            if result.socialProfiles.isEmpty {
                emptyTab("No social profiles found", "person.slash")
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(Array(result.socialProfiles.enumerated()), id: \.element.id) { i, p in
                        socialCard(p, index: i)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
    }

    private func socialCard(_ p: SocialProfile, index: Int) -> some View {
        let opacity = cardOpacities.indices.contains(index) ? cardOpacities[index] : 1
        let offset = cardOffsets.indices.contains(index) ? cardOffsets[index] : 0

        return Link(destination: p.platformURL ?? URL(string: "https://\(p.platform.lowercased())")!) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color(hex: p.color).opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: sfIcon(p.platform))
                        .foregroundColor(Color(hex: p.color)).font(.footnote)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(p.platform).font(.subheadline.weight(.semibold)).foregroundColor(.white)
                    if let u = p.username {
                        Text(u).font(.caption).foregroundColor(.white.opacity(0.45))
                    } else {
                        Text("Profile").font(.caption).foregroundColor(.white.opacity(0.3))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(p.confidenceLabel).font(.caption2.weight(.bold)).foregroundColor(p.confidenceColor)
                    Text("\(p.confidence)%").font(.caption2).foregroundColor(.white.opacity(0.3))
                }

                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.2))
            }
            .padding(14).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 1))
            .opacity(opacity).offset(y: offset)
        }
    }

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
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.type).font(.subheadline.weight(.semibold)).foregroundColor(.white)
                                    Text(r.source).font(.caption).foregroundColor(.white.opacity(0.45))
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.2))
                            }
                            .padding(14).background(r.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(r.color.opacity(0.2), lineWidth: 0.5))
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
    }

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

    private func animateCards() {
        let count = result.socialProfiles.count + result.criminalRecords.count + result.otherMatches.count
        cardOffsets = Array(repeating: 30, count: count)
        cardOpacities = Array(repeating: 0, count: count)
        for i in 0..<count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(i) * 0.04)) {
                if cardOffsets.indices.contains(i) { cardOffsets[i] = 0 }
                if cardOpacities.indices.contains(i) { cardOpacities[i] = 1 }
            }
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
            self.init(red: Double((i >> 16) & 0xFF) / 255,
                      green: Double((i >> 8) & 0xFF) / 255,
                      blue: Double(i & 0xFF) / 255)
        } else { self = .gray }
    }
}
