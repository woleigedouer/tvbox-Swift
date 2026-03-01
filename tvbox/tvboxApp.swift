import SwiftUI
import SwiftData

@main
struct tvboxApp: App {
    @StateObject private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VodCollect.self,
            VodRecord.self,
            CacheItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var apiConfig = ApiConfig.shared
    @Published var isConfigLoaded = false
    @Published var currentSourceKey: String = ""
    #if os(macOS)
    @Published var splitViewVisibility: NavigationSplitViewVisibility = .all
    private var splitViewVisibilityBeforePlayerFullScreen: NavigationSplitViewVisibility?
    #endif
    
    func loadConfig(url: String) async {
        do {
            try await ApiConfig.shared.loadConfig(from: url)
            await MainActor.run {
                self.isConfigLoaded = true
                self.currentSourceKey = ApiConfig.shared.homeSourceBean?.key ?? ""
            }
        } catch {
            print("Failed to load config: \(error)")
        }
    }
    
    #if os(macOS)
    func enterPlayerFullScreen() {
        if splitViewVisibilityBeforePlayerFullScreen == nil {
            splitViewVisibilityBeforePlayerFullScreen = splitViewVisibility
        }
        splitViewVisibility = .detailOnly
    }
    
    func exitPlayerFullScreen() {
        guard let previous = splitViewVisibilityBeforePlayerFullScreen else { return }
        splitViewVisibility = previous
        splitViewVisibilityBeforePlayerFullScreen = nil
    }
    #endif
}
