//
//  PhysicsDropView.swift
//  nouriapp
//
//  UIKit Dynamics — blocks are injected DIRECTLY into the UIWindow
//  so the animator's reference view is the entire screen.
//  This means global CGRects work perfectly and blocks fall
//  all the way off screen with no clipping.
//

import SwiftUI
import UIKit

// MARK: - Snapshot model
struct IngredientSnapshot {
    let info: IngredientInfo
    let frame: CGRect   // global screen coordinates
}

// MARK: - SwiftUI trigger wrapper (zero-size, invisible)
struct PhysicsDropOverlay: UIViewRepresentable {
    let ingredients: [IngredientSnapshot]
    let trigger: Int

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard trigger > 0 else { return }
        DispatchQueue.main.async {
            // Fire into the shared window-level canvas safely
            WindowPhysicsManager.shared.startDrop(snapshots: ingredients, trigger: trigger, fallbackWindow: uiView.window)
        }
    }
}

// MARK: - Singleton window-level physics manager
final class WindowPhysicsManager {

    static let shared = WindowPhysicsManager()
    private init() {}

    private var animator: UIDynamicAnimator?
    private var activeBlocks: [UIView] = []
    private var lastTrigger = 0

    func startDrop(snapshots: [IngredientSnapshot], trigger: Int, fallbackWindow: UIWindow?) {
        guard trigger != lastTrigger else { return }
        lastTrigger = trigger

        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first ?? fallbackWindow else { return }

        // ─── Cleanup ────────────────────────────────────────────────────────
        animator?.removeAllBehaviors()
        activeBlocks.forEach { $0.removeFromSuperview() }
        activeBlocks.removeAll()

        // ─── Create blocks at exact global positions ─────────────────────────
        for snapshot in snapshots {
            let block = makeBlockView(for: snapshot)
            window.addSubview(block)
            activeBlocks.append(block)
        }

        guard !activeBlocks.isEmpty else { return }

        // ─── UIKit Dynamics (Matthew Palmer pattern) ─────────────────────────
        animator = UIDynamicAnimator(referenceView: window)

        for (i, block) in activeBlocks.enumerated() {
            let itemGravity = UIGravityBehavior(items: [block])
            itemGravity.magnitude = CGFloat.random(in: 2.5...3.5)
            
            let itemBehavior = UIDynamicItemBehavior(items: [block])
            itemBehavior.elasticity = 0.0
            itemBehavior.resistance = 0.1
            itemBehavior.allowsRotation = true
            itemBehavior.angularResistance = 0.1
            
            let spinDir: CGFloat = i % 2 == 0 ? 1.0 : -1.0
            itemBehavior.addAngularVelocity(CGFloat.random(in: 1.5...3.0) * spinDir, for: block)
            
            animator?.addBehavior(itemGravity)
            animator?.addBehavior(itemBehavior)
        }

        // Auto-cleanup after blocks have had time to fully fall off screen
        let blockCount = activeBlocks.count
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.lastTrigger == trigger else { return }
            self.cleanup()
        }
    }

    private func cleanup() {
        animator?.removeAllBehaviors()
        activeBlocks.forEach { $0.removeFromSuperview() }
        activeBlocks.removeAll()
        animator = nil
    }

    private func makeBlockView(for snapshot: IngredientSnapshot) -> UIView {
        let frame = snapshot.frame
        let container = UIView(frame: frame)
        // Restored subtle red coordination
        container.backgroundColor = UIColor(red: 254/255, green: 244/255, blue: 243/255, alpha: 1)
        container.layer.cornerRadius = 10
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 245/255, green: 225/255, blue: 222/255, alpha: 1).cgColor
        
        // Premium 3D shadow for the falling pieces
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 8
        container.layer.shadowOpacity = 0.08
        
        container.clipsToBounds = false

        let label = UILabel()
        label.text = snapshot.info.label
        label.textColor = UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1)
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.frame = CGRect(x: 12, y: 0, width: frame.width - 50, height: frame.height)
        container.addSubview(label)

        let circleSize: CGFloat = 22
        let circle = UIView(frame: CGRect(x: frame.width - circleSize - 12, y: (frame.height - circleSize) / 2, width: circleSize, height: circleSize))
        circle.layer.cornerRadius = circleSize / 2
        circle.backgroundColor = UIColor(red: 192/255, green: 57/255, blue: 43/255, alpha: 0.1)

        let icon = UIImageView(image: UIImage(systemName: "xmark"))
        icon.frame = CGRect(x: 6, y: 6, width: 10, height: 10)
        icon.tintColor = UIColor(red: 192/255, green: 57/255, blue: 43/255, alpha: 1)
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        circle.addSubview(icon)

        container.addSubview(circle)
        return container
    }
}
