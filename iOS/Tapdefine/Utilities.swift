//
//  Utilities.swift
//  Tapdefine
//
//  Created by Hamik on 6/28/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit
import AVFoundation

class Utilities: NSObject {
    
    static var AudioPlayer: AVAudioPlayer?
    
    static func GetProp<T>(named prop: String, from jsonDictionary: [String: Any]) -> T? {
        if let val = jsonDictionary[prop] as? T {
            return val
        }
        return nil
    }
    
    static func Mod(_ a: Int, _ n: Int) -> Int {
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }
    
    static func Exp(_ a: Int, _ b: Int) -> Int {
        var prod = 1
        for _ in 0..<b {
            prod = prod * a
        }
        return prod
    }
    
    static func Increment(array: inout [Int], startingAt index: Int, by: Int) {
        guard index >= 0, index < array.count else {
            print("Index out of bounds in Utilities.Increment")
            return
        }
        for i in index..<array.count {
            array[i] += by
        }
    }
    
    static func PlaySoundAux(localUrl url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // This line would be different for iOS10. Might change for > iOS12, too...
            AudioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = AudioPlayer else { return }
            player.play()
        } catch let error {
            print("Audio playback error", error.localizedDescription)
        }
    }
    
    static func PlaySound(url: URL?) {
        guard let url = url else { return }
        
        if !url.isFileURL {
            let task = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
                guard let localURL = localURL, error == nil else {
                    print("Could not download pronunciation mp3. Not playing.", error ?? "")
                    return
                }
                print("Downloaded pronunciation mp3!")
                PlaySoundAux(localUrl: localURL)
            }
            task.resume()
        } else {
            PlaySoundAux(localUrl: url)
        }
    }
    
    static func ConvertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
