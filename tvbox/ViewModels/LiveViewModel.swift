import Foundation
import SwiftUI

/// 直播 ViewModel
@MainActor
class LiveViewModel: ObservableObject {
    @Published var channelGroups: [LiveChannelGroup] = []
    @Published var selectedGroupIndex: Int = 0
    @Published var selectedChannelIndex: Int = 0
    @Published var currentChannel: LiveChannelItem?
    @Published var epgList: [Epginfo] = []
    @Published var isLoading = false
    @Published var showChannelList = false
    
    /// 加载直播频道
    func loadChannels() {
        self.channelGroups = ApiConfig.shared.liveChannelGroupList
        if let firstGroup = channelGroups.first, let firstChannel = firstGroup.channels.first {
            currentChannel = firstChannel
        }
    }
    
    /// 选择频道分组
    func selectGroup(_ index: Int) {
        guard index >= 0, index < channelGroups.count else { return }
        selectedGroupIndex = index
        selectedChannelIndex = 0
        if let first = channelGroups[index].channels.first {
            selectChannel(first)
        }
    }
    
    /// 选择频道
    func selectChannel(_ channel: LiveChannelItem) {
        currentChannel = channel
        loadEPG(for: channel)
    }
    
    /// 上一个频道
    func previousChannel() {
        guard !channelGroups.isEmpty else { return }
        if selectedChannelIndex > 0 {
            selectedChannelIndex -= 1
        } else if selectedGroupIndex > 0 {
            selectedGroupIndex -= 1
            selectedChannelIndex = channelGroups[selectedGroupIndex].channels.count - 1
        }
        if let ch = channelGroups[selectedGroupIndex].channels[safe: selectedChannelIndex] {
            selectChannel(ch)
        }
    }
    
    /// 下一个频道
    func nextChannel() {
        guard !channelGroups.isEmpty else { return }
        let group = channelGroups[selectedGroupIndex]
        if selectedChannelIndex < group.channels.count - 1 {
            selectedChannelIndex += 1
        } else if selectedGroupIndex < channelGroups.count - 1 {
            selectedGroupIndex += 1
            selectedChannelIndex = 0
        }
        if let ch = channelGroups[selectedGroupIndex].channels[safe: selectedChannelIndex] {
            selectChannel(ch)
        }
    }
    
    /// 切换线路
    func switchSource() {
        currentChannel?.nextSource()
    }
    
    /// 当前频道列表
    var currentChannels: [LiveChannelItem] {
        guard selectedGroupIndex < channelGroups.count else { return [] }
        return channelGroups[selectedGroupIndex].channels
    }
    
    /// 加载 EPG 节目单
    private func loadEPG(for channel: LiveChannelItem) {
        // EPG 加载 - 简化实现
        epgList = []
    }
}

// 安全数组下标访问
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
