//
//  EditMenuBridge.swift
//  Momoto
//
//  Created by Kezia Meilany Tandapai on 27/05/26.
//

import SwiftUI
import UIKit

struct EditMenuAction {
    let title: String
    let isDestructive: Bool
    let handler: () -> Void
    
    init(title: String, isDestructive: Bool = false, handler: @escaping () -> Void) {
        self.title = title
        self.isDestructive = isDestructive
        self.handler = handler
    }
}

struct EditMenuBridge: UIViewRepresentable {
    let isPresented: Bool
    let actions: [EditMenuAction]
    let onDismiss: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let interaction = UIEditMenuInteraction(delegate: context.coordinator)
        view.addInteraction(interaction)
        context.coordinator.interaction = interaction
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.actions = actions
        context.coordinator.onDismiss = onDismiss
        
        let wasPresented = context.coordinator.isPresented
        context.coordinator.isPresented = isPresented
        
        if isPresented && !wasPresented {
            DispatchQueue.main.async {
                guard uiView.window != nil else { return }
                let sourcePoint = CGPoint(x: uiView.bounds.midX, y: uiView.bounds.minY)
                let configuration = UIEditMenuConfiguration(identifier: nil, sourcePoint: sourcePoint)
                context.coordinator.interaction?.presentEditMenu(with: configuration)
            }
        } else if !isPresented && wasPresented {
            DispatchQueue.main.async {
                context.coordinator.interaction?.dismissMenu()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIEditMenuInteractionDelegate {
        var interaction: UIEditMenuInteraction?
        var actions: [EditMenuAction] = []
        var onDismiss: () -> Void = {}
        var isPresented: Bool = false
        
        func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
            let menuActions = actions.map { action in
                UIAction(
                    title: action.title,
                    attributes: action.isDestructive ? .destructive : []
                ) { _ in
                    action.handler()
                }
            }
            return UIMenu(children: menuActions)
        }
        
        func editMenuInteraction(_ interaction: UIEditMenuInteraction, willDismissMenuFor configuration: UIEditMenuConfiguration, animator: UIEditMenuInteractionAnimating) {
            animator.addCompletion {
                self.isPresented = false
                self.onDismiss()
            }
        }
    }
}
