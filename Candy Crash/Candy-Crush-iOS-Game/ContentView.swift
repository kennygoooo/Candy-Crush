//
//  ContentView.swift
//  Candy-Crush-iOS-Game
//
//  
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var game = Game()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                TitleView(game: game)
                TimerView(game: game, geometry: geometry)
                GameGridsView(game: game)
                if !game.isPlaying {
                    Button {
                        game.gameStart()
                    } label: {
                        Text("Game Start")
                            .bold()
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 229/255, green: 96/255, blue: 96/255))
                            .cornerRadius(5)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            .aspectRatio(contentMode: .fit)
        }
        .background(Color(red: 250/255, green: 248/255, blue: 239/255))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
