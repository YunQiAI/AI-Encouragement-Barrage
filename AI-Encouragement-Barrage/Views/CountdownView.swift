//
//  CountdownView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import SwiftUI

struct CountdownView: View {
    @State private var countdown = 3
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            Text("\(countdown)")
                .font(.system(size: 48, weight: .bold))
                .onAppear {
                    startCountdown()
                }
        }
        .frame(width: 200, height: 100)
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            
            if countdown <= 0 {
                timer.invalidate()
                onComplete()
            }
        }
    }
}

#Preview {
    CountdownView {
        print("Countdown completed")
    }
}
