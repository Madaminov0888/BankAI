//
//  LocalFileManager.swift
//  CustomChat
//
//  Created by Muhammadjon Madaminov on 08/01/25.
//



import Foundation
import SwiftUI
import AVKit
import Combine

import Foundation

class LocalFileManager {

    
    /// Saves media to local storage
    func saveMedia(data: Data, key: String, media: MediaTypes) {
        guard let path = getPath(key: key, media: media) else {
            print("Error getting path for saving media")
            return
        }
        
        do {
            try data.write(to: path)
            print("Success saving data at: \(path)")
        } catch let error {
            print("Error writing data: \(error)")
        }
    }
    
    /// Gets the path for a specific media type
    func getPath(key: String, media: MediaTypes) -> URL? {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("\(key)\(media.rawValue)")
    }
    
    /// Retrieves media from local storage if it exists
    func getMedia(key: String, media: MediaTypes) -> URL? {
        guard
            let path = getPath(key: key, media: media),
            FileManager.default.fileExists(atPath: path.path) else {
            print("Media not found in cache")
            return nil
        }
        return path
    }
}

/// Enum for Media Types
enum MediaTypes: String {
    case video = ".mp4"
    case imageJPG = ".jpg"
    case imageJPEG = ".jpeg"
    case imagePNG = ".png"
    case audio = ".wav"
}

/// Custom error handling
enum FileManagerError: Error {
    case invalidDataConversion
    case fileSaveFailed
}
