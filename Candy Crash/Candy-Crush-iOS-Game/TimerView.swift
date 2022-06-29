//
//  TimerView.swift
//  Candy-Crush-iOS-Game
//
//  
//

import SwiftUI

struct TimerView: View {
    
    @ObservedObject var game: Game
    
    var geometry: GeometryProxy
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .frame(height: 40)
                .foregroundColor(Color(red: 253/255, green: 216/255, blue: 212/255))
            
            Capsule()
                .frame(width: (geometry.size.width-32)*CGFloat(Double(game.gameTimeLast)/30.0), height: 40)
                .foregroundColor(Color(red: 1, green: 146/255, blue: 146/255))
                .overlay(alignment: .trailing) {
                    if game.gameTimeLast > 15 {
                        Text("\(game.gameTimeLast)")
                            .bold()
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.trailing, 8)
                    }
                }
        }
        .overlay(alignment: .leading) {
            if game.gameTimeLast <= 15 {
                Text("\(game.gameTimeLast)")
                    .bold()
                    .font(.title)
                    .foregroundColor(Color(red: 120/255, green: 111/255, blue: 102/255))
                    .padding(.leading, 8)
            }
        }
    }
}
