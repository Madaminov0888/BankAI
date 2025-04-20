//
//  String+.swift
//  BankAI
//
//  Created by Muhammadjon Madaminov on 20/04/25.
//

import Foundation

extension String {
    /// Attempts to parse an ISO‑8601 timestamp (with fractional seconds),
    /// even if it’s missing a timezone designator.
    var iso8601Date: Date? {
        // 1) Try ISO8601DateFormatter without expecting a 'Z' or offset:
        let isoNoTZ = ISO8601DateFormatter()
        isoNoTZ.formatOptions = [
            .withFullDate,
            .withTime,
            .withFractionalSeconds
        ]
        isoNoTZ.timeZone = TimeZone(secondsFromGMT: 0)  // you can adjust if your timestamps are local
        if let date = isoNoTZ.date(from: self) {
            return date
        }

        // 2) Fallback: Use DateFormatter with an explicit format string:
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return df.date(from: self)
    }

    /// Converts an ISO‑8601 timestamp into a localized,
    /// human-readable string. If parsing fails, returns `self`.
    ///
    /// - Parameters:
    ///   - dateStyle: the desired date style (default: .medium)
    ///   - timeStyle: the desired time style (default: .short)
    ///   - locale: the locale for formatting (default: current)
    /// - Returns: formatted string or the original string on failure.
    func toReadableDate(
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .short,
        locale: Locale = .current
    ) -> String {
        guard let date = self.iso8601Date else {
            // Couldn't parse—just return the original
            return self
        }

        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = locale
        return formatter.string(from: date)
    }
}
