//
//  TitleView.swift
//  Candy-Crush-iOS-Game
//
//  
//

import SwiftUI

struct TitleView: View {
    
    @ObservedObject var game: Game
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Candy Crush")
                .font(.largeTitle.bold())
                .foregroundColor(Color(red: 229/255, green: 96/255, blue: 96/255))
            
            Spacer()
            
            Text("BEST \(game.bestScore)")
                .bold()
                .font(.title)
                .foregroundColor(.white)
                .padding(.vertical, 5)
                .frame(maxWidth: 140)
                .background(Color(red: 229/255, green: 96/255, blue: 96/255))
                .cornerRadius(5)
        }
    }
}
