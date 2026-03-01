import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle().stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.bottom, 8)
            
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white.opacity(0.9))
                .tracking(1)
            
            if let message = message {
                Text(message)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(40)
        .glassCard(cornerRadius: 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
