import SwiftUI

/// 剧集列表组件 - 对应 Android 版 SeriesAdapter
struct EpisodeListView: View {
    let episodes: [VodInfo.Episode]
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    
    @State private var currentGroup = 0
    private let groupSize = 50
    
    private var groupCount: Int {
        max(1, (episodes.count + groupSize - 1) / groupSize)
    }
    
    private var currentEpisodes: [VodInfo.Episode] {
        let start = currentGroup * groupSize
        let end = min(start + groupSize, episodes.count)
        guard start < episodes.count else { return [] }
        return Array(episodes[start..<end])
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 分组选择
            if groupCount > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<groupCount, id: \.self) { group in
                            let start = group * groupSize + 1
                            let end = min((group + 1) * groupSize, episodes.count)
                            Button {
                                withAnimation {
                                    currentGroup = group
                                }
                            } label: {
                                Text("\(start)-\(end)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(currentGroup == group ? .white : .white.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        ZStack {
                                            if currentGroup == group {
                                                Capsule().fill(Color.white.opacity(0.15))
                                            } else {
                                                Capsule().fill(Color.white.opacity(0.05))
                                            }
                                        }
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // 剧集网格
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [
                    GridItem(.fixed(44)),
                    GridItem(.fixed(44))
                ], spacing: 10) {
                    ForEach(Array(currentEpisodes.enumerated()), id: \.offset) { index, episode in
                        let actualIndex = currentGroup * groupSize + index
                        Button {
                            onSelect(actualIndex)
                        } label: {
                            Text(episode.name)
                                .font(.system(size: 13, weight: actualIndex == selectedIndex ? .bold : .medium))
                                .foregroundColor(actualIndex == selectedIndex ? .white : .white.opacity(0.7))
                                .frame(minWidth: 70)
                                .frame(height: 44)
                                .background(
                                    ZStack {
                                        if actualIndex == selectedIndex {
                                            AppTheme.accentGradient
                                        } else {
                                            Color.white.opacity(0.05)
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(actualIndex == selectedIndex ? Color.clear : Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 100)
        }
    }
}
