//
//  EncryptionManagerReport.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 06/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import Foundation

/// Encryption Manager report structure.
struct EncryptionManagerReport {
    var timestamp: String
    var content: String
    
    init(content: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateFormatterFormat = Constants.timestampFormat
        dateFormatter.dateFormat = dateFormatterFormat
        timestamp = dateFormatter.string(from: Date())
        self.content = content
    }
}
