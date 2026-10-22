//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit

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
            let newLength = newValue.utf16.count
            let location = min(selectionOffset, newLength)
            var newSelection = NSRange(location: location, length: min(selectionLength, newLength - location))

            // A UTF-16 range can split a Character even after conversion to String.Index.
            // Preserve those selections in UIKit's coordinate space instead of matching Characters.
            if let selection = Range(NSRange(location: selectionOffset, length: selectionLength), in: oldValue),
               (selection.lowerBound == oldValue.endIndex || oldValue.indices.contains(selection.lowerBound)),
               (selection.upperBound == oldValue.endIndex || oldValue.indices.contains(selection.upperBound))
            {
                let characterOffset = oldValue.distance(from: oldValue.startIndex, to: selection.lowerBound)
                let characterLength = oldValue.distance(from: selection.lowerBound, to: selection.upperBound)
                let index = selection.isEmpty ? selection.lowerBound : oldValue.index(before: selection.upperBound)
                var start = newValue.index(newValue.startIndex, offsetBy: characterOffset, limitedBy: newValue.endIndex) ?? newValue.endIndex
                var end = newValue.index(start, offsetBy: characterLength, limitedBy: newValue.endIndex) ?? newValue.endIndex
                if let range = oldValue.commonPrefixRange(from: index, in: newValue, minLength: max(1, characterLength)),
                   let matchedStart = newValue.index(range.upperBound, offsetBy: -max(1, characterLength), limitedBy: range.lowerBound)
                {
                    start = matchedStart
                    end = selection.isEmpty ? start : range.upperBound
                }
                newSelection = NSRange(start..<end, in: newValue)
            }

            setText(newValue)
            if let from = position(from: beginningOfDocument, offset: newSelection.location),
               let to = position(from: from, offset: newSelection.length)
            {
                selectedTextRange = textRange(from: from, to: to)
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
        if prefix(startIndexOffset).lowercased() == target.prefix(startIndexOffset).lowercased() {
            guard let end = target.index(target.startIndex, offsetBy: startIndexOffset + 1, limitedBy: target.endIndex) else {
                return nil
            }
            return target.startIndex..<end
        }
        let delta = target.count - count
        let maxOffset = max(0, min(startIndexOffset + max(0, delta), target.count - 1))
        let minOffset = max(0, min(startIndexOffset + min(0, delta), target.count - 1))

        var index = index
        var indexOffset = startIndexOffset
        var targetIndex = target.index(target.startIndex, offsetBy: maxOffset)
        var targetIndexOffset = maxOffset
        let targetMinIndex = target.index(target.startIndex, offsetBy: minOffset)
        var count = 0
        while index >= startIndex, targetIndex >= target.startIndex {
            let isMatch = self[index].lowercased() == target[targetIndex].lowercased()
            if isMatch {
                count += 1
            } else if count > 0, targetIndexOffset == indexOffset {
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
                indexOffset -= 1
            }
            target.formIndex(before: &targetIndex)
            targetIndexOffset -= 1
        }
        guard count >= minLength else { return nil }
        guard let end = target.index(targetIndex, offsetBy: count, limitedBy: target.endIndex) else { return nil }
        return targetIndex..<end
    }
}

#endif
