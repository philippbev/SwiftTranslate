import SwiftUI
import AppKit

/// Reliable multiline text input using NSTextView with native placeholder support.
struct MultilineTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var isEditable: Bool = true
    var onPaste: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let sv = NSTextView.scrollableTextViewWithPlaceholder()
        guard let tv = sv.documentView as? PlaceholderTextView else { return sv }
        tv.delegate = context.coordinator
        tv.isEditable = isEditable
        tv.isSelectable = true
        tv.isRichText = false
        tv.allowsUndo = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.font = .systemFont(ofSize: 15)
        tv.textContainerInset = NSSize(width: 10, height: 10)
        tv.backgroundColor = .clear
        tv.drawsBackground = false
        sv.drawsBackground = false
        sv.borderType = .noBorder
        tv.placeholderText = placeholder
        tv.onPaste = { context.coordinator.parent.onPaste?() }
        return sv
    }

    func updateNSView(_ sv: NSScrollView, context: Context) {
        guard let tv = sv.documentView as? PlaceholderTextView else { return }
        tv.isEditable = isEditable
        tv.placeholderText = placeholder
        tv.onPaste = { context.coordinator.parent.onPaste?() }
        context.coordinator.parent = self

        // Never overwrite text while the user is actively editing this view
        guard !context.coordinator.isEditing else { return }

        if tv.string != text {
            let selected = tv.selectedRanges
            tv.string = text
            tv.selectedRanges = selected
            tv.needsDisplay = true
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MultilineTextField
        var isEditing = false

        init(_ parent: MultilineTextField) { self.parent = parent }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }
    }
}

// MARK: - NSTextView subclass with placeholder + paste detection

final class PlaceholderTextView: NSTextView {
    var placeholderText: String = "" {
        didSet { needsDisplay = true }
    }
    var onPaste: (() -> Void)?

    override func paste(_ sender: Any?) {
        super.paste(sender)
        onPaste?()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.placeholderTextColor,
            .font: font ?? NSFont.systemFont(ofSize: 15)
        ]
        let inset = textContainerInset
        let x = inset.width + (textContainer?.lineFragmentPadding ?? 0)
        let y = inset.height
        NSAttributedString(string: placeholderText, attributes: attrs)
            .draw(at: NSPoint(x: x, y: y))
    }
}

// MARK: - NSScrollView factory

extension NSTextView {
    static func scrollableTextViewWithPlaceholder() -> NSScrollView {
        let sv = NSScrollView()
        sv.hasVerticalScroller = true
        sv.autohidesScrollers = true
        let tv = PlaceholderTextView()
        tv.autoresizingMask = [.width]
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        sv.documentView = tv
        return sv
    }
}
