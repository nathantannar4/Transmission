//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import XCTest
@testable import Transmission

final class UITextInputSelectionTests: XCTestCase {

    @MainActor
    func testUpdatingTextPreservesSelectionAtCharacterBoundaries() throws {
        let cases: [(old: String, new: String, selection: NSRange, expected: NSRange)] = [
            ("😀😀a", "😀😀ab", NSRange(location: 4, length: 0), NSRange(location: 4, length: 0)),
            ("😀😀a", "😀😀ab", NSRange(location: 2, length: 2), NSRange(location: 2, length: 2)),
            ("👨‍👩‍👧‍👦ab", "👨‍👩‍👧‍👦abc", NSRange(location: 11, length: 0), NSRange(location: 11, length: 0)),
            ("e\u{301}ab", "e\u{301}abc", NSRange(location: 2, length: 0), NSRange(location: 2, length: 0)),
            ("İab", "i\u{307}abc", NSRange(location: 1, length: 0), NSRange(location: 2, length: 0)),
            ("abcdef", "abcd", NSRange(location: 4, length: 0), NSRange(location: 4, length: 0)),
            ("abcdef", "abcd", NSRange(location: 5, length: 0), NSRange(location: 4, length: 0)),
            ("abcdef", "abcd", NSRange(location: 3, length: 2), NSRange(location: 3, length: 1)),
            ("😀😀abc", "😀😀", NSRange(location: 5, length: 0), NSRange(location: 4, length: 0)),
            ("abcdef", "😀", NSRange(location: 4, length: 0), NSRange(location: 2, length: 0)),
            ("abcdef", "Xabcdef", NSRange(location: 3, length: 0), NSRange(location: 4, length: 0)),
            ("abcdef", "Xabcdef", NSRange(location: 2, length: 2), NSRange(location: 3, length: 2)),
            ("abcDEF", "ABCdef", NSRange(location: 2, length: 2), NSRange(location: 2, length: 2)),
            ("abcdef", "abcXdef", NSRange(location: 3, length: 0), NSRange(location: 3, length: 0)),
            ("abc", "😀abc", NSRange(location: 1, length: 0), NSRange(location: 3, length: 0)),
        ]

        for test in cases {
            let label = "\(test.old.debugDescription) -> \(test.new.debugDescription), \(test.selection)"
            let textField = UITextField()
            textField.text = test.old
            try setSelection(test.selection, in: textField)
            textField.setTextPreservingSelection(test.new, isFormatted: false)
            XCTAssertEqual(textField.text, test.new, label)
            XCTAssertEqual(try selection(in: textField), test.expected, label)

            let textView = UITextView()
            textView.text = test.old
            try setSelection(test.selection, in: textView)
            textView.setTextPreservingSelection(test.new)
            XCTAssertEqual(textView.text, test.new, label)
            XCTAssertEqual(try selection(in: textView), test.expected, label)
        }
    }

    @MainActor
    func testUpdatingTextPreservesUTF16SelectionsInsideCharacters() throws {
        let cases: [(old: String, new: String, selection: NSRange, expected: NSRange)] = [
            ("e\u{301}ab", "e\u{301}abc", NSRange(location: 0, length: 1), NSRange(location: 0, length: 1)),
            ("e\u{301}ab", "e\u{301}abc", NSRange(location: 1, length: 0), NSRange(location: 1, length: 0)),
            ("e\u{301}ab", "e\u{301}abc", NSRange(location: 1, length: 1), NSRange(location: 1, length: 1)),
            ("e\u{301}ab", "e\u{301}", NSRange(location: 1, length: 2), NSRange(location: 1, length: 1)),
            ("😀ab", "😀abc", NSRange(location: 0, length: 1), NSRange(location: 0, length: 1)),
            ("😀ab", "😀abc", NSRange(location: 1, length: 1), NSRange(location: 1, length: 1)),
            ("👨‍👩‍👧‍👦ab", "👨‍👩‍👧‍👦abc", NSRange(location: 3, length: 4), NSRange(location: 3, length: 4)),
            ("👨‍👩‍👧‍👦ab", "a", NSRange(location: 3, length: 4), NSRange(location: 1, length: 0)),
        ]

        for test in cases {
            let label = "\(test.old.debugDescription) -> \(test.new.debugDescription), \(test.selection)"
            let textField = UITextField()
            textField.text = test.old
            try setSelection(test.selection, in: textField)
            XCTAssertEqual(try selection(in: textField), test.selection, label)
            textField.setTextPreservingSelection(test.new, isFormatted: false)
            XCTAssertEqual(textField.text, test.new, label)
            XCTAssertEqual(try selection(in: textField), test.expected, label)

            let textView = UITextView()
            textView.text = test.old
            try setSelection(test.selection, in: textView)
            XCTAssertEqual(try selection(in: textView), test.selection, label)
            textView.setTextPreservingSelection(test.new)
            XCTAssertEqual(textView.text, test.new, label)
            XCTAssertEqual(try selection(in: textView), test.expected, label)
        }
    }

    @MainActor
    func testBoundarySelectionsAndClearingText() throws {
        let cases: [(selection: NSRange, new: String, expected: NSRange)] = [
            (NSRange(location: 0, length: 0), "😀abcd", NSRange(location: 0, length: 0)),
            (NSRange(location: 5, length: 0), "😀abcd", NSRange(location: 6, length: 0)),
            (NSRange(location: 0, length: 5), "😀abcd", NSRange(location: 0, length: 6)),
            (NSRange(location: 3, length: 0), "", NSRange(location: 0, length: 0)),
        ]

        for test in cases {
            let textField = UITextField()
            textField.text = "😀abc"
            try setSelection(test.selection, in: textField)
            textField.setTextPreservingSelection(test.new, isFormatted: false)
            XCTAssertEqual(try selection(in: textField), test.expected)
        }
    }

    @MainActor
    func testFormattedTextPreservesUTF16DistanceFromEnd() throws {
        let textField = UITextField()
        textField.text = "😀abc"
        try setSelection(NSRange(location: 2, length: 0), in: textField)
        textField.setTextPreservingSelection("😀aXbc", isFormatted: true)
        XCTAssertEqual(try selection(in: textField), NSRange(location: 3, length: 0))
    }

    @MainActor
    private func setSelection(_ selection: NSRange, in input: UITextInput) throws {
        let start = try XCTUnwrap(input.position(from: input.beginningOfDocument, offset: selection.location))
        let end = try XCTUnwrap(input.position(from: start, offset: selection.length))
        input.selectedTextRange = try XCTUnwrap(input.textRange(from: start, to: end))
    }

    @MainActor
    private func selection(in input: UITextInput) throws -> NSRange {
        let range = try XCTUnwrap(input.selectedTextRange)
        return NSRange(
            location: input.offset(from: input.beginningOfDocument, to: range.start),
            length: input.offset(from: range.start, to: range.end)
        )
    }
}

#endif
