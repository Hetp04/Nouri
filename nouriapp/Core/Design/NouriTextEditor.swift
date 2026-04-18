import SwiftUI
import UIKit

/// A custom editor that allows separate control over line spacing (for wrapping)
/// and paragraph spacing (for new lines).
struct NouriTextEditor: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont = .systemFont(ofSize: 18)
    var lineSpacing: CGFloat = 4
    var paragraphSpacing: CGFloat = 14
    var foregroundColor: UIColor = .label
    var accentColor: UIColor = .systemBlue
    var textContainerInset: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = foregroundColor
        textView.tintColor = accentColor
        textView.textContainerInset = textContainerInset
        textView.textContainer.lineFragmentPadding = 0
        
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.dataDetectorTypes = []
        textView.alwaysBounceVertical = false // No wiggle
        textView.showsVerticalScrollIndicator = false
        
        // Custom Swipe to Dismiss (since bounce is disabled)
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        textView.addGestureRecognizer(pan)
        
        textView.typingAttributes = typingAttributes
        
        context.coordinator.textView = textView
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.attributedText = NSAttributedString(string: text, attributes: typingAttributes)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private var typingAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        
        return [
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
    }

    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: NouriTextEditor
        weak var textView: UITextView?

        init(_ parent: NouriTextEditor) {
            self.parent = parent
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let tv = textView, tv.isFirstResponder else { return }
            let translation = gesture.translation(in: tv)
            let velocity = gesture.velocity(in: tv)
            
            // If dragging down significantly or with high velocity
            if translation.y > 60 || velocity.y > 500 {
                tv.resignFirstResponder()
            }
        }

        // Allow our pan gesture to work alongside the UITextView's internal gestures
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            textView.typingAttributes = parent.typingAttributes
        }
    }
}
