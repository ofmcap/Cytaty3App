// Views/QuoteRowView.swift
import SwiftUI

struct QuoteRowView: View {
    let quote: Quote
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(quote.content).font(.body)
            HStack(spacing: 8) {
                if let page = quote.page {
                    Text("\(String(localized: "QUOTE_PAGE_SHORT")) \(page)")
                        .font(.caption).foregroundColor(.secondary)
                }
                if let ch = quote.chapter {
                    Text("\(String(localized: "QUOTE_CHAPTER_SHORT")) \(ch)")
                        .font(.caption).foregroundColor(.secondary)
                }
                if !quote.tags.isEmpty {
                    Text(quote.tags.joined(separator: ", "))
                        .font(.caption2).foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
