import SwiftUI

struct ResultsView: View {
    let result: SearchResponse
    var onReset: () -> Void

    @State private var animateItems = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Results")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(result.totalMatches) matches")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                    Button(action: onReset) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if result.socialProfiles.isEmpty {
                            noResultsView
                        } else {
                            statsBar
                            socialSection
                        }

                        if !result.otherMatches.isEmpty {
                            otherSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear { animateItems = true }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.2))
            Text("No social profiles found")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Try a clearer photo with better lighting")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }

    private var statsBar: some View {
        HStack(spacing: 0) {
            statItem(count: result.socialProfiles.count, label: "Social Profiles", color: .green)
            Divider().frame(height: 30).background(.white.opacity(0.1))
            statItem(count: result.otherMatches.count, label: "Other Sites", color: .blue)
            Divider().frame(height: 30).background(.white.opacity(0.1))
            statItem(count: result.totalMatches, label: "Total Matches", color: .orange)
        }
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Media Profiles")
                .font(.headline)
                .foregroundColor(.white)

            LazyVStack(spacing: 8) {
                ForEach(Array(result.socialProfiles.enumerated()), id: \.element.id) { idx, profile in
                    ProfileRow(profile: profile)
                        .offset(y: animateItems ? 0 : 30)
                        .opacity(animateItems ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(idx) * 0.06), value: animateItems)
                }
            }
        }
    }

    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Other Web Matches")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))

            LazyVStack(spacing: 6) {
                ForEach(result.otherMatches.prefix(15)) { match in
                    Link(destination: URL(string: match.url)!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.white.opacity(0.4))
                            Text(match.url)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(match.confidenceLabel)
                                .font(.caption2)
                                .foregroundColor(confidenceColor(match.confidence))
                        }
                        .padding(12)
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func confidenceColor(_ val: Int) -> Color {
        if val >= 80 { return .green }
        if val >= 60 { return .yellow }
        if val >= 40 { return .orange }
        return .red.opacity(0.6)
    }
}

struct ProfileRow: View {
    let profile: SocialProfile

    var body: some View {
        Link(destination: profile.platformURL ?? URL(string: "https://\(profile.platform.lowercased())")!) {
            HStack(spacing: 14) {
                // Platform icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(PlatformColor.color(for: profile.platformColor)).opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: platformIcon)
                        .font(.title3)
                        .foregroundColor(Color(PlatformColor.color(for: profile.platformColor)))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.platform)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    if let username = profile.username {
                        Text(username)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("Profile found")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(profile.confidenceLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(confidenceColor)
                    Text("\(profile.confidence)%")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.35))
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(12)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var confidenceColor: Color {
        if profile.confidence >= 80 { return .green }
        if profile.confidence >= 60 { return .yellow }
        if profile.confidence >= 40 { return .orange }
        return .red.opacity(0.6)
    }

    private var platformIcon: String {
        switch profile.platform.lowercased() {
        case let s where s.contains("instagram"): return "camera.viewfinder"
        case let s where s.contains("tiktok"): return "music.note"
        case let s where s.contains("facebook"): return "f.square"
        case let s where s.contains("twitter"), let s where s.contains("x"): return "bird"
        case let s where s.contains("snapchat"): return "flame"
        case let s where s.contains("linkedin"): return "link"
        case let s where s.contains("youtube"): return "play.rectangle"
        case let s where s.contains("reddit"): return "bubble.left"
        case let s where s.contains("pinterest"): return "pin"
        case let s where s.contains("github"): return "chevron.left.forwardslash.chevron.right"
        case let s where s.contains("onlyfans"): return "lock"
        case let s where s.contains("discord"): return "bubble.left.and.bubble.right"
        case let s where s.contains("telegram"): return "paperplane"
        case let s where s.contains("twitch"): return "tv"
        case let s where s.contains("patreon"): return "heart"
        case let s where s.contains("threads"): return "at"
        case let s where s.contains("snapchat"): return "ghost"
        default: return "person.circle"
        }
    }
}

#Preview {
    ResultsView(
        result: SearchResponse(
            success: true,
            totalMatches: 12,
            socialProfiles: [
                SocialProfile(platform: "Instagram", platformColor: "#E4405F", url: "https://instagram.com/testuser", username: "@testuser", confidence: 92),
                SocialProfile(platform: "TikTok", platformColor: "#000000", url: "https://tiktok.com/@test", username: "@test", confidence: 78),
            ],
            otherMatches: [
                OtherMatch(url: "https://example.com/photo.jpg", confidence: 55)
            ]
        ),
        onReset: {}
    )
}
