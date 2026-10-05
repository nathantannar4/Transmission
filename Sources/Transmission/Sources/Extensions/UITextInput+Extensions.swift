//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import Playgrounds

extension UITextField {

    func setTextPreservingSelection(_ newValue: String, isFormatted: Bool) {
        updateTextPreservingSelection(
            newValue,
            isFormatted: isFormatted,
            text: { text },
            setText: { text = $0 }
        )
    }
}

extension UITextView {

    func setTextPreservingSelection(_ newValue: String) {
        updateTextPreservingSelection(
            newValue,
            isFormatted: false,
            text: { text },
            setText: { text = $0 }
        )
    }
}

extension UITextInput {

    func updateTextPreservingSelection(
        _ newValue: String,
        isFormatted: Bool = false,
        text: () -> String?,
        setText: (String) -> Void
    ) {
        let text = text()
        guard text != newValue else { return }
        guard !newValue.isEmpty else {
            setText(newValue)
            return
        }
        guard markedTextRange == nil else { return }
        guard let oldValue = text, let selectedRange = selectedTextRange else {
            setText(newValue)
            return
        }

        if selectedRange.start == endOfDocument, selectedRange.end == endOfDocument {
            setText(newValue)
            selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        } else if selectedRange.start == beginningOfDocument, selectedRange.end == beginningOfDocument {
            setText(newValue)
            selectedTextRange = textRange(from: beginningOfDocument, to: beginningOfDocument)
        } else if selectedRange.start == beginningOfDocument, selectedRange.end == endOfDocument {
            setText(newValue)
            selectedTextRange = textRange(from: beginningOfDocument, to: endOfDocument)
        } else if isFormatted {
            let distanceFromEnd = offset(from: selectedRange.start, to: endOfDocument)
            setText(newValue)
            if let newPosition = position(from: endOfDocument, offset: -distanceFromEnd) {
                selectedTextRange = textRange(from: newPosition, to: newPosition)
            } else {
                selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
            }
        } else {
            let selectionOffset = offset(from: beginningOfDocument, to: selectedRange.start)
            let selectionLength = offset(from: selectedRange.start, to: selectedRange.end)
            setText(newValue)
            let index = oldValue.index(oldValue.startIndex, offsetBy: selectionOffset + max(0, selectionLength - 1))
            if let range = oldValue.lowercased().commonPrefixRange(from: index, in: newValue.lowercased(), minLength: max(1, selectionLength)) {
                let offset = newValue.distance(from: newValue.startIndex, to: range.upperBound)
                if let from = position(from: beginningOfDocument, offset: offset - max(1, selectionLength)), let to = position(from: from, offset: selectionLength) {
                    selectedTextRange = textRange(from: from, to: to)
                }
            }
        }
    }
}

extension String {

    func commonPrefixRange(
        from index: String.Index,
        in target: String,
        minLength: Int
    ) -> Range<String.Index>? {
        guard index < endIndex, index >= startIndex, !target.isEmpty else { return nil }
        let startIndexOffset = distance(from: startIndex, to: index)
        if prefix(startIndexOffset) == target.prefix(startIndexOffset) {
            let end = target.index(target.startIndex, offsetBy: startIndexOffset + 1)
            return target.startIndex..<end
        }
        let delta = target.count - count
        let maxOffset = max(0, min(startIndexOffset + max(0, delta), target.count - 1))
        let minOffset = max(0, min(startIndexOffset + min(0, delta), target.count - 1))

        var index = index
        var targetIndex = target.index(target.startIndex, offsetBy: maxOffset)
        let targetMinIndex = target.index(target.startIndex, offsetBy: minOffset)
        var count = 0
        while index >= startIndex, targetIndex >= target.startIndex {
            let isMatch = self[index] == target[targetIndex]
            if isMatch {
                count += 1
            } else if count > 0, targetIndex == index {
                target.formIndex(after: &targetIndex)
                break
            } else if targetIndex < targetMinIndex {
                break
            }
            if index == startIndex || targetIndex == target.startIndex {
                break
            }
            if isMatch {
                formIndex(before: &index)
            }
            target.formIndex(before: &targetIndex)
        }
        guard count >= minLength else { return nil }
        let end = target.index(targetIndex, offsetBy: count)
        return targetIndex..<end
    }
}

#endif
