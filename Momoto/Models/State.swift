//
//  State.swift
//  Momoto
//
//  Created by Kezia Meilany Tandapai on 07/05/26.
//

enum ProcessingState {
    case loading
    case success(MindMap)
    case failure(String)
}
