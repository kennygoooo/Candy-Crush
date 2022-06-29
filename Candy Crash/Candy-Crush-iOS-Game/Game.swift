//
//  Game.swift
//  Candy-Crush-iOS-Game
//
//  
//

import Foundation
import SwiftUI

enum GridType { case blank, oval, drop, app, circle, row, column, bomb, gift }

struct Grid {
    var gridType: GridType
    var foregroundColor: Color {
        switch self.gridType {
        case .blank: return .clear
        case .oval: return .orange
        case .drop: return Color(red: 237/255, green: 195/255, blue: 1/255)
        case .app: return .green
        case .circle: return .blue
        case .row: return .red
        case .column: return .red
        case .bomb: return .purple
        case .gift: return Color(red: 152/255, green: 76/255, blue: 11/255)
        }
    }
    var systemName: String {
        switch self.gridType {
        case .blank: return ""
        case .oval: return "candy1"
        case .drop: return "candy2"
        case .app: return "candy3"
        case .circle: return "candy4"
        case .row: return "candy5"
        case .column: return "candy6"
        case .bomb: return "candy7"
        case .gift: return "candy8"
        }
    }
}

class Game: ObservableObject {
    
    @AppStorage("bestScore") var bestScore = 0
    
    @Published var grids = Array(repeating: Grid(gridType: .blank), count: 63)
    @Published var score = 0
    @Published var combo = 0
    @Published var isMatch = false
    @Published var isProcessing = false
    
    @Published var gameTimeLast = 30
    @Published var isPlaying = false
    @Published var isStop = false
    
    private var startDate: Date?
    private var timer: Timer?
    
    func timerStart() {
        isStop = false
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.gameTimeLast -= 1
            if(self.gameTimeLast == 0) {
                self.timer?.invalidate()
                self.timer = nil
                if self.score > self.bestScore {
                    self.bestScore = self.score
                }
                self.isPlaying = false
                self.grids = Array(repeating: Grid(gridType: .blank), count: 63)
                self.gameTimeLast = 30
            }
        }
    }
    
    func timerStop() {
        isStop = true
        timer?.invalidate()
        timer = nil
    }
    
    func gameStart() {
        self.score = 0
        self.gameTimeLast = 30
        isPlaying = true
        withAnimation(.linear(duration: 0.4)) {
            (0...62).forEach { index in
                grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                if [2...6, 9...13].joined().contains(index) {
                    while([grids[index-2], grids[index-1]].allSatisfy({ $0.gridType == grids[index].gridType })) {
                        grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                    }
                } else if [stride(from: 14, to: 56, by: 7), stride(from: 15, to: 57, by: 7)].joined().contains(index) {
                    while([grids[index-14], grids[index-7]].allSatisfy({ $0.gridType == grids[index].gridType })) {
                        grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                    }
                } else if ![0, 1, 7, 8].contains(index) {
                    while(
                        [grids[index-2], grids[index-1]].allSatisfy({ $0.gridType == grids[index].gridType })
                        ||
                        [grids[index-14], grids[index-7]].allSatisfy({ $0.gridType == grids[index].gridType })
                    ) {
                        grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                    }
                }
            }
        }
        self.timerStart()
    }
    
    func checkMatch() {
        var checkList = Array(repeating: false, count: 63)
        // check row to generate checkList
        for row in 0...8 {
            for column in 0...4 {
                if [.oval, .drop, .app, .circle].contains(grids[row*7+column].gridType) && [grids[row*7+column+1], grids[row*7+column+2]].allSatisfy({ $0.gridType == grids[row*7+column].gridType }) {
                    (row*7+column...row*7+column+2).forEach { checkList[$0] = true }
                    isMatch = true
                }
            }
        }
        // check column to generate checkList
        for row in 0...6 {
            for column in 0...6 {
                if [.oval, .drop, .app, .circle].contains(grids[row*7+column].gridType) && [grids[row*7+column+7], grids[row*7+column+14]].allSatisfy({ $0.gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+14, by: 7).forEach { checkList[$0] = true }
                    isMatch = true
                }
            }
        }
        // check row 3
        for row in 0...8 {
            for column in 0...4 {
                if (row*7+column...row*7+column+2).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    (row*7+column...row*7+column+2).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        (row*7+column...row*7+column+2).forEach { grids[$0].gridType = .blank }
                    }
                    score += 3
                    combo += 1
                }
            }
        }
        // check column 3
        for row in 0...6 {
            for column in 0...6 {
                if stride(from: row*7+column, through: row*7+column+7*2, by: 7).allSatisfy({ checkList[$0] == true && grids[$0].gridType == grids[row*7+column].gridType }) {
                    stride(from: row*7+column, through: row*7+column+7*2, by: 7).forEach { checkList[$0] = false }
                    withAnimation(.linear(duration: 0.4)) {
                        stride(from: row*7+column, through: row*7+column+7*2, by: 7).forEach { grids[$0].gridType = .blank }
                    }
                    score += 3
                    combo += 1
                }
            }
        }
        // clear
        (0...62).forEach { index in
            if checkList[index] == true {
                withAnimation(.linear(duration: 0.4)) {
                    grids[index].gridType = .blank
                }
                score += 1
            }
        }
        if isMatch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.fallDown()
            }
        } else {
            combo = 0
            if self.checkDead() {
                grids.shuffle()
                self.fallDown()
            } else {
                isProcessing = false
            }
        }
    }
    
    func fallDown() {
        while grids.contains(where: { $0.gridType == .blank }) {
            (0...62).forEach { index in
                if grids[index].gridType == .blank {
                    if (0...6).contains(index) {
                        grids[index].gridType = [.oval, .drop, .app, .circle].randomElement()!
                    } else {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            grids.swapAt(index, index-7)
                        }
                    }
                }
            }
        }
        isMatch = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.checkMatch()
        }
    }
    
    func clearAll() {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids = Array(repeating: Grid(gridType: .blank), count: 63)
        }
        score += 63
        combo += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func manyBomb(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        let randomGridType: GridType = [.oval, .drop, .app, .circle].randomElement()!
        (0...62).forEach { index in
            if grids[index].gridType == randomGridType {
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[index].gridType = .bomb
                }
            }
        }
        (0...62).forEach { index in
            if grids[index].gridType == .bomb {
                self.bomb(index: index)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func manyRow(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        let randomGridType: GridType = [.oval, .drop, .app, .circle].randomElement()!
        (0...62).forEach { index in
            if grids[index].gridType == randomGridType {
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[index].gridType = .row
                }
            }
        }
        (0...62).forEach { index in
            if grids[index].gridType == .row {
                self.row(index: index)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func manyColumn(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        let randomGridType: GridType = [.oval, .drop, .app, .circle].randomElement()!
        (0...62).forEach { index in
            if grids[index].gridType == randomGridType {
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[index].gridType = .column
                }
            }
        }
        (0...62).forEach { index in
            if grids[index].gridType == .column {
                self.column(index: index)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func bigBomb(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        self.bomb(index: first)
        self.bomb(index: second)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func bigCross(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        if second == 0 {
            self.row(index: 0)
            self.row(index: 7)
            self.column(index: 0)
            self.column(index: 1)
        } else if second == 6 {
            self.row(index: 0)
            self.row(index: 7)
            self.column(index: 5)
            self.column(index: 6)
        } else if second == 56 {
            self.row(index: 49)
            self.row(index: 56)
            self.column(index: 0)
            self.column(index: 1)
        } else if second == 62 {
            self.row(index: 49)
            self.row(index: 56)
            self.column(index: 5)
            self.column(index: 6)
        } else if (1...5).contains(second) {
            self.row(index: 0)
            self.row(index: 7)
            self.column(index: second-1)
            self.column(index: second)
            self.column(index: second+1)
        } else if stride(from: 7, through: 49, by: 7).contains(second) {
            self.row(index: second-7)
            self.row(index: second)
            self.row(index: second+7)
            self.column(index: 0)
            self.column(index: 1)
        } else if stride(from: 13, through: 55, by: 7).contains(second) {
            self.row(index: second-7)
            self.row(index: second)
            self.row(index: second+7)
            self.column(index: 5)
            self.column(index: 5)
        } else if (57...61).contains(second) {
            self.row(index: 49)
            self.row(index: 56)
            self.column(index: second-1)
            self.column(index: second)
            self.column(index: second+1)
        } else {
            self.row(index: second-7)
            self.row(index: second)
            self.row(index: second+7)
            self.column(index: second-1)
            self.column(index: second)
            self.column(index: second+1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func cross(first: Int, second: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[first].gridType = .blank
            grids[second].gridType = .blank
        }
        score += 2
        combo += 1
        self.row(index: second)
        self.column(index: second)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fallDown()
        }
    }
    
    func gift(gridType: GridType, index: Int) {
        isMatch = true
        grids[index].gridType = .blank
        score += 1
        (0...62).forEach { idx in
            if grids[idx].gridType == gridType {
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[idx].gridType = .blank
                }
                score += 1
            }
        }
        combo += 1
    }
    
    func bomb(index: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[index].gridType = .blank
        }
        score += 1
        if index == 0 {
            [1, 7, 8].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if index == 6 {
            [5, 12, 13].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if index == 56 {
            [49, 50, 57].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if index == 62 {
            [54, 55, 61].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if (1...5).contains(index) {
            [index-1, index+1, index+6, index+7, index+8].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if stride(from: 7, through: 49, by: 7).contains(index) {
            [index-7, index-6, index+1, index+7, index+8].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if stride(from: 13, through: 55, by: 7).contains(index) {
            [index-8, index-7, index-1, index+6, index+7].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else if (57...61).contains(index) {
            [index-8, index-7, index-6, index-1, index+1].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        } else {
            [index-8, index-7, index-6, index-1, index+1, index+6, index+7, index+8].forEach { idx in
                switch grids[idx].gridType {
                case .blank:
                    break;
                case .row:
                    self.row(index: idx)
                case .column:
                    self.column(index: idx)
                case .bomb:
                    self.bomb(index: idx)
                case .gift:
                    self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
                default:
                    withAnimation(.easeInOut(duration: 0.4)) {
                        grids[idx].gridType = .blank
                    }
                    score += 1
                }
            }
        }
        combo += 1
    }
    
    func row(index: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[index].gridType = .blank
        }
        score += 1
        (7*(index/7)...7*(index/7)+6).forEach { idx in
            switch grids[idx].gridType {
            case .blank:
                break;
            case .column:
                self.column(index: idx)
            case .bomb:
                self.bomb(index: idx)
            case .gift:
                self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
            default:
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[idx].gridType = .blank
                }
                score += 1
            }
        }
        combo += 1
    }
    
    func column(index: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            grids[index].gridType = .blank
        }
        score += 1
        stride(from: index%7, through: index%7+7*8, by: 7).forEach { idx in
            switch grids[idx].gridType {
            case .blank:
                break;
            case .row:
                self.row(index: idx)
            case .bomb:
                self.bomb(index: idx)
            case .gift:
                self.gift(gridType: [.oval, .drop, .app, .circle].randomElement()!, index: idx)
            default:
                withAnimation(.easeInOut(duration: 0.4)) {
                    grids[idx].gridType = .blank
                }
                score += 1
            }
        }
        combo += 1
    }
    
    func checkDead() -> Bool {
        if grids.contains(where: { [.row, .column, .bomb, .gift].contains($0.gridType) }) {
            return false
        }
        var testGrids = grids
        // test row
        for index in 0...62 {
            if !stride(from: 6, through: 62, by: 7).contains(index) {
                testGrids.swapAt(index, index+1)
                // check row to generate checkList
                for row in 0...8 {
                    for column in 0...4 {
                        if [.oval, .drop, .app, .circle].contains(testGrids[row*7+column].gridType) && [testGrids[row*7+column+1], testGrids[row*7+column+2]].allSatisfy({ $0.gridType == testGrids[row*7+column].gridType }) {
                            return false
                        }
                    }
                }
                // check column to generate checkList
                for row in 0...6 {
                    for column in 0...6 {
                        if [.oval, .drop, .app, .circle].contains(testGrids[row*7+column].gridType) && [testGrids[row*7+column+7], testGrids[row*7+column+14]].allSatisfy({ $0.gridType == testGrids[row*7+column].gridType }) {
                            return false
                        }
                    }
                }
                testGrids.swapAt(index, index+1)
            }
        }
        // test column
        for index in 0...62 {
            if !(56...62).contains(index) {
                testGrids.swapAt(index, index+7)
                // check row to generate checkList
                for row in 0...8 {
                    for column in 0...4 {
                        if [.oval, .drop, .app, .circle].contains(testGrids[row*7+column].gridType) && [testGrids[row*7+column+1], testGrids[row*7+column+2]].allSatisfy({ $0.gridType == testGrids[row*7+column].gridType }) {
                            return false
                        }
                    }
                }
                // check column to generate checkList
                for row in 0...6 {
                    for column in 0...6 {
                        if [.oval, .drop, .app, .circle].contains(testGrids[row*7+column].gridType) && [testGrids[row*7+column+7], testGrids[row*7+column+14]].allSatisfy({ $0.gridType == testGrids[row*7+column].gridType }) {
                            return false
                        }
                    }
                }
                testGrids.swapAt(index, index+7)
            }
        }
        return true
    }
}
