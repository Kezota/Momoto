//
//  Helper.swift
//  Momoto
//
//  Created by Kezia Meilany Tandapai on 07/05/26.
//

import SwiftUI
import UIKit

// Each top-level branch (a direct child of the root) gets its own color, which every
// descendant of that branch inherits — so a whole subtree reads as one visual group.
private let branchPalette: [Color] = [
    Theme.green,
    Theme.teal,
    Theme.yellow,
    Theme.red,
    Theme.blue,
    Theme.purple
]

/// Background fill for a node: solid brand color for the root and each branch's header
/// node, fading to a soft tint of that branch's color for everything beneath it.
func nodeFillColor(depth: Int, branchIndex: Int?) -> Color {
    guard depth > 0, let branchIndex else {
        return Theme.purple // root
    }
    let color = branchPalette[branchIndex % branchPalette.count]
    return depth == 1 ? color : color.opacity(0.14)
}

/// Text/icon color for a node — light on the solid root/branch-header fills, dark on the soft tints.
func nodeTextColor(depth: Int) -> Color {
    depth <= 1 ? .white : Theme.textPrimary
}

/// Connector line color, matching the branch it belongs to.
func branchLineColor(branchIndex: Int?) -> Color {
    guard let branchIndex else { return Theme.textSecondary.opacity(0.6) }
    return branchPalette[branchIndex % branchPalette.count].opacity(0.8)
}

// MARK: - Node sizing

/// Nodes grow to fit long titles (up to a cap) instead of clipping the title behind an ellipsis.
let nodeMinHeight: CGFloat = 58
private let nodeMaxLines = 5
private let nodeHorizontalPadding: CGFloat = 24  // 12pt leading + trailing content padding
private let nodeAccessoryWidth: CGFloat = 44     // icon + trailing chevron/spinner + spacing
private let nodeVerticalPadding: CGFloat = 20    // 10pt top + bottom content padding

/// Height a node needs to show its full title (wrapped, up to `nodeMaxLines`) without truncating.
/// Used both to size the SwiftUI node view and to space rows in the layout engine, so the two stay in sync.
func nodeHeight(title: String, depth: Int) -> CGFloat {
    // Measure with the rounded design the node actually renders in; the default design's
    // slightly narrower metrics were undercounting lines for long titles, which is what
    // caused visible truncation despite the "grow to fit" sizing.
    let base = UIFont.preferredFont(forTextStyle: depth == 0 ? .headline : .subheadline)
    let weight: UIFont.Weight = depth == 0 ? .bold : .semibold
    let font: UIFont
    if let rounded = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
        .fontDescriptor.withDesign(.rounded) {
        font = UIFont(descriptor: rounded, size: base.pointSize)
    } else {
        font = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
    }
    // Small safety margin so a word that *just* fits in measurement can't wrap in rendering.
    let availableWidth = MindmapNodeView.width - nodeHorizontalPadding - nodeAccessoryWidth - 4
    let bounding = (title as NSString).boundingRect(
        with: CGSize(width: max(availableWidth, 1), height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
    )
    let maxTextHeight = font.lineHeight * CGFloat(nodeMaxLines)
    let textHeight = min(ceil(bounding.height), ceil(maxTextHeight))
    return max(nodeMinHeight, ceil(textHeight + nodeVerticalPadding))
}
