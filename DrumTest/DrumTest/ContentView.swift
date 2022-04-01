// Copyright AudioKit. All Rights Reserved.

import AudioKit
import SwiftUI
import AVFoundation
import Combine
import SwiftUI

struct DrumSample {
    var name: String
    var fileName: String
    var midiNote: Int
    var audioFile: AVAudioFile?
    var darken: DarwinBoolean

    init(_ prettyName: String, file: String, note: Int, dark: DarwinBoolean) {
        name = prettyName
        fileName = file
        midiNote = note
        darken = dark

        guard let url = Bundle.main.resourceURL?.appendingPathComponent(file) else { return }
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            Log("Could not load: $fileName")
        }
    }
}

class DrumsConductor: ObservableObject {
    // Mark Published so View updates label on changes
    @Published private(set) var lastPlayed: String = "None"

    let engine = AudioEngine()

    let drumSamples: [DrumSample] =
        [
            DrumSample("OPEN HI HAT", file: "Samples/open_hi_hat_A#1.wav", note: 34, dark: false),
            DrumSample("HI TOM", file: "Samples/hi_tom_D2.wav", note: 38, dark: false),
            DrumSample("MID TOM", file: "Samples/mid_tom_B1.wav", note: 35, dark: false),
            DrumSample("LO TOM", file: "Samples/lo_tom_F1.wav", note: 29, dark: false),
            DrumSample("HI HAT", file: "Samples/closed_hi_hat_F#1.wav", note: 30, dark: false),
            DrumSample("CLAP", file: "Samples/clap_D#1.wav", note: 27, dark: false),
            DrumSample("SNARE", file: "Samples/snare_D1.wav", note: 26, dark: false),
            DrumSample("KICK", file: "Samples/bass_drum_C1.wav", note: 24, dark: false),
        ]

    let drums = AppleSampler()

    func playPad(padNumber: Int) {
        drums.play(noteNumber: MIDINoteNumber(drumSamples[padNumber].midiNote))
        let fileName = drumSamples[padNumber].fileName
        lastPlayed = fileName.components(separatedBy: "/").last!
    }

    func start() {
        engine.output = drums
        do {
            try engine.start()
        } catch {
            Log("AudioKit did not start! \(error)")
        }
        do {
            let files = drumSamples.map {
                $0.audioFile!
                
            }
            try drums.loadAudioFiles(files)

        } catch {
            Log("Files Didn't Load")
        }
    }

    func stop() {
        engine.stop()
    }
}

struct PadsView: View {
    var conductor: DrumsConductor
    var padsAction: (_ padNumber: Int) -> Void
    @State var downPads: [Int] = []
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { column in
                        ZStack {
                           Image("ButtonPad")
                        }
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({_ in
                            if !(self.downPads.contains(where: { $0 == row * 4 + column})) {
                                self.padsAction(getPadId(row: row, column: column))
                            }
                        }).onEnded({_ in
                        }))
        
                    }
                }
            }
        }

    }
}

struct ContentView: View {
    @StateObject var conductor = DrumsConductor()

    var body: some View {
        TabView{
        VStack(spacing: 2) {
            PadsView(conductor: conductor) { pad in
                self.conductor.playPad(padNumber: pad)
            }
        }
        .onAppear {
            self.conductor.start()
        }
        .onDisappear {
            self.conductor.stop()
        }
        .tabItem{
            Image(systemName: "house.fill")
            Text("Home")
        }
            
            Text("Profile Tab")
                   .font(.system(size: 30, weight: .bold, design: .rounded))
                   .tabItem {
                       Image(systemName: "person.crop.circle")
                       Text("Profile")
                   }
            
    }
    .onAppear() {
            UITabBar.appearance().barTintColor = .gray
    }
    .accentColor(.orange)
}
}

private func getPadId(row: Int, column: Int) -> Int {
    return (row * 4) + column
}

struct DrumsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
.previewInterfaceOrientation(.portrait)
    }
}
