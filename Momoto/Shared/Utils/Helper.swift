//
//  Helper.swift
//  Momoto
//
//  Created by Kezia Meilany Tandapai on 07/05/26.
//

import SwiftUI

// Each depth level gets a soft tint of the brand palette
func colorForDepth(_ depth: Int) -> Color {
    switch depth {
    case 0:  return Theme.purple.opacity(0.10)  // root  – soft purple
    case 1:  return Theme.green.opacity(0.10)   // L1    – soft green
    case 2:  return Theme.yellow.opacity(0.10)  // L2    – soft yellow
    default: return Theme.red.opacity(0.08)     // deep  – soft red
    }
}
