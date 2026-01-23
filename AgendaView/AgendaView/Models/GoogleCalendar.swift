//
//  GoogleCalendar.swift
//  AgendaView
//

import Foundation

struct GoogleCalendar: Identifiable, Codable, Hashable {
    let id: String
    let summary: String
    let colorId: String?
    let backgroundColor: String?
    var isSelected: Bool

    init(id: String, summary: String, colorId: String? = nil, backgroundColor: String? = nil, isSelected: Bool = true) {
        self.id = id
        self.summary = summary
        self.colorId = colorId
        self.backgroundColor = backgroundColor
        self.isSelected = isSelected
    }
}
