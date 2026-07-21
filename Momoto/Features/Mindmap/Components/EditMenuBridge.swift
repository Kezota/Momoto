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
    let icon: String?
    let isDestructive: Bool
    let handler: () -> Void

    init(title: String, icon: String? = nil, isDestructive: Bool = false, handler: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.handler = handler
    }
}

struct EditMenuSection {
    let actions: [EditMenuAction]
    /// When true, renders as a horizontal row of icon-over-label buttons (like the system Cut/Copy/Paste strip) instead of a stacked list.
    let isCompact: Bool

    init(_ actions: [EditMenuAction], isCompact: Bool = false) {
        self.actions = actions
        self.isCompact = isCompact
    }
}

struct EditMenuBridge: UIViewRepresentable {
    let isPresented: Bool
    let sections: [EditMenuSection]
    let onDismiss: () -> Void

    init(isPresented: Bool, sections: [EditMenuSection], onDismiss: @escaping () -> Void) {
        self.isPresented = isPresented
        self.sections = sections.filter { !$0.actions.isEmpty }
        self.onDismiss = onDismiss
    }

    init(isPresented: Bool, actions: [EditMenuAction], onDismiss: @escaping () -> Void) {
        self.init(isPresented: isPresented, sections: [EditMenuSection(actions)], onDismiss: onDismiss)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        let interaction = UIEditMenuInteraction(delegate: context.coordinator)
        view.addInteraction(interaction)
        context.coordinator.interaction = interaction

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.sections = sections
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
        var sections: [EditMenuSection] = []
        var onDismiss: () -> Void = {}
        var isPresented: Bool = false

        func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
            let groups = sections.map { section -> UIMenu in
                let menuActions = section.actions.map { action in
                    UIAction(
                        title: action.title,
                        image: action.icon.flatMap { UIImage(systemName: $0) },
                        attributes: action.isDestructive ? .destructive : []
                    ) { _ in
                        action.handler()
                    }
                }
                return UIMenu(
                    options: .displayInline,
                    preferredElementSize: section.isCompact ? .medium : .automatic,
                    children: menuActions
                )
            }
            return UIMenu(children: groups)
        }
        
        func editMenuInteraction(_ interaction: UIEditMenuInteraction, willDismissMenuFor configuration: UIEditMenuConfiguration, animator: UIEditMenuInteractionAnimating) {
            animator.addCompletion {
                self.isPresented = false
                self.onDismiss()
            }
        }
    }
}
