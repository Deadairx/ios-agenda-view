//
//  WidgetModels.swift
//  AgendaWidget
//

import Foundation
import SwiftUI

struct WidgetCalendarEvent: Identifiable, Codable {
    let id: String
    let title: String
    let startDate: Date
    let isAllDay: Bool
    let colorHex: String

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var formattedTime: String {
        if isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: startDate).lowercased()
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(startDate)
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
