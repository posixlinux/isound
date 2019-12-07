//
//  ViewController.swift
//  isound
//
//  Created by Ghost on 2019/12/07.
//  Copyright © 2019 jsl. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet private weak var micView: TouchView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.setupMicView()
    }
    
    private func setupMicView() {
        // mic 권한 요청
        self.micView.setup()
    }
}

private protocol TouchViewDelegate {
    func didStartTouch()
    func didEndTouch()
}

class TouchView: UIView {
    private var startDate: Date?
    private var session: AVAudioSession = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var valid: Bool = false
    
    func setup() {
        do {
            try self.session.setCategory(.playAndRecord, mode: .default)
            try self.session.setActive(true)
            self.session.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self?.backgroundColor = UIColor.blue
                        self?.valid = true
                    } else {
                        self?.backgroundColor = UIColor.red
                        self?.valid = false
                    }
                }
            }
        } catch let error {
            print("error : \(error)")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard self.valid else { return }
        
        self.startDate = Date()
        
        self.startRecording()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let startDate = self.startDate else { return }
        
        let endDate: Date = Date()
        let diff: TimeInterval = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
        self.startDate = nil
        
        self.stopRecording()
        
        // 1초 미만이면 기록한 파일을 삭제
        if diff < 1 {
            if let url: URL = self.audioFilePath() {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let error {
                    print("error : \(error)f")
                }
            }
        }
    }
    
    @IBAction func touchReplay(_ sender: Any) {
        if self.player?.isPlaying == true {
            self.player?.stop()
            self.player = nil
        }
        
        guard let audioFileURL: URL = self.audioFilePath() else { return }
        
        do {
            self.player = try AVAudioPlayer(contentsOf: audioFileURL)
        } catch let error {
            print("error : \(error)")
        }
        
        self.player?.prepareToPlay()
        self.player?.play()
    }
    
    private func audioFilePath() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("recording.m4a")
    }
    
    private func startRecording() {
        guard let audioFileURL: URL = self.audioFilePath() else { return }
        
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 12000,
                        AVNumberOfChannelsKey: 2,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        do {
            self.recorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            self.recorder?.delegate = self
            self.recorder?.record()
        } catch let error {
            print("error : \(error)")
        }
    }
    
    private func stopRecording() {
        self.recorder?.stop()
        self.recorder = nil
    }
}

extension TouchView: AVAudioRecorderDelegate {
    
}
