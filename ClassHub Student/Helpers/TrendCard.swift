//
//  TrendCard.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/30/25.
//
import SwiftUI
import Foundation

// Top-level TrendItem model used across the app
struct TrendItem: Identifiable {
    enum Direction { case up, down, same }
    let id = UUID()
    let title: String
    let subtitle: String
    let color: Color
    let direction: Direction
}

// MARK: - TrendCard
// Public/internal so other views can reuse it
struct TrendCard: View {
    let item: TrendItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // neutral circular background
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 48, height: 48)
                    // colored pill
                    Group {
                        switch item.direction {
                        case .up:
                            Image(systemName: "arrow.up")
                                .foregroundColor(.green)
                        case .down:
                            Image(systemName: "arrow.down")
                                .foregroundColor(.red)
                        case .same:
                            Image(systemName: "minus")
                                .foregroundColor(.orange)
                        }
                    }
                    .font(.largeTitle)
                    .frame(width: 26, height: 6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                HStack(spacing: 6) {
                    // trend indicator
                    Group {
                        switch item.direction {
                        case .up:
                            Image(systemName: "arrow.up")
                                .foregroundColor(.green)
                        case .down:
                            Image(systemName: "arrow.down")
                                .foregroundColor(.red)
                        case .same:
                            Image(systemName: "minus")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)

                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), trend \(accessibilityText(for: item.direction)), value \(item.subtitle)")
    }

    private func accessibilityText(for dir: TrendItem.Direction) -> String {
        switch dir {
        case .up: return "up"
        case .down: return "down"
        case .same: return "unchanged"
        }
    }
}
