import SwiftUI

/// 根视图 - 对应 Android 版 HomeActivity 的 TabView 导航
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var settingsVM = SettingsViewModel()
    @State private var selectedTab = 0
    @State private var showSetup = false
    
    var body: some View {
        Group {
            if appState.isConfigLoaded {
                mainTabView
            } else {
                setupView
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // 自动加载已保存的配置
            let savedUrl = UserDefaults.standard.string(forKey: HawkConfig.API_URL) ?? ""
            if !savedUrl.isEmpty {
                Task {
                    await appState.loadConfig(url: savedUrl)
                }
            }
        }
    }
    
    // MARK: - 主界面
    
    private var mainTabView: some View {
        #if os(iOS)
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)
            
            LiveView()
                .tabItem {
                    Label("直播", systemImage: "tv.fill")
                }
                .tag(1)
            
            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            FavoritesView()
                .tabItem {
                    Label("收藏", systemImage: "heart.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.orange)
        #else
        NavigationSplitView(columnVisibility: $appState.splitViewVisibility) {
            List(selection: $selectedTab) {
                Label("首页", systemImage: "house.fill")
                    .tag(0)
                Label("直播", systemImage: "tv.fill")
                    .tag(1)
                Label("搜索", systemImage: "magnifyingglass")
                    .tag(2)
                Label("收藏", systemImage: "heart.fill")
                    .tag(3)
                Label("历史", systemImage: "clock.fill")
                    .tag(5)
                Label("设置", systemImage: "gearshape.fill")
                    .tag(4)
            }
            .navigationTitle("TVBox")
            .listStyle(.sidebar)
        } detail: {
            switch selectedTab {
            case 0: HomeView()
            case 1: LiveView()
            case 2: SearchView()
            case 3: FavoritesView()
            case 4: SettingsView()
            case 5: HistoryView()
            default: HomeView()
            }
        }
        #endif
    }
    
    // MARK: - 首次配置页面
    
    private var setupView: some View {
        ZStack {
            // 背景装饰
            AppTheme.primaryGradient
                .ignoresSafeArea()
            
            // 装饰性光晕
            VStack {
                HStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: -100, y: -100)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: 100, y: 100)
                }
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Logo 区域
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentGradient)
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)
                                .opacity(0.5)
                            
                            Image(systemName: "play.tv.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    AppTheme.accentGradient
                                )
                                .shadow(color: .red.opacity(0.3), radius: 15, x: 0, y: 10)
                        }
                        
                        VStack(spacing: 8) {
                            Text("TVBox")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(2)
                            
                            Text("极致视听 · 简洁至上")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(4)
                        }
                    }
                    .padding(.top, 60)
                    
                    // 输入表单
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("接口配置")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.orange)
                                TextField("请输入接口地址 (URL)", text: $settingsVM.apiUrl)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    #if os(iOS)
                                    .autocapitalization(.none)
                                    .keyboardType(.URL)
                                    #endif
                                
                                Button {
                                    #if os(iOS)
                                    if let text = UIPasteboard.general.string {
                                        settingsVM.apiUrl = text
                                    }
                                    #else
                                    if let text = NSPasteboard.general.string(forType: .string) {
                                        settingsVM.apiUrl = text
                                    }
                                    #endif
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .foregroundColor(.orange)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .glassCard(cornerRadius: 15)
                        }
                        
                        // 确认按钮
                        Button {
                            Task {
                                await settingsVM.loadConfig()
                                if settingsVM.configSuccess {
                                    await appState.loadConfig(url: settingsVM.apiUrl)
                                }
                            }
                        } label: {
                            HStack {
                                if settingsVM.isLoadingConfig {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 8)
                                }
                                Text(settingsVM.isLoadingConfig ? "正在解析配置..." : "开启影音之旅")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accentGradient)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: .red.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .disabled(settingsVM.isLoadingConfig || settingsVM.apiUrl.isEmpty)
                        
                        // 历史记录
                        if !settingsVM.apiHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("最近使用")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 4)
                                
                                ForEach(settingsVM.apiHistory.prefix(3), id: \.self) { url in
                                    Button {
                                        settingsVM.apiUrl = url
                                    } label: {
                                        HStack {
                                            Image(systemName: "clock.arrow.2.circlepath")
                                                .font(.caption)
                                            Text(url)
                                                .font(.caption)
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 8))
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .foregroundColor(.white.opacity(0.7))
                                        .glassCard(cornerRadius: 10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // 错误提示
                    if let error = settingsVM.configError {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(error)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .glassCard(cornerRadius: 10)
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
        }
    }
}
