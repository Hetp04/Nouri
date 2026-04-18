//
//  DailyNoteViewModel.swift
//  nouriapp
//
//  Owns the text state for one day's note.
//
//  Flow:
//    1. On load: fetches text (from server or cache)
//    2. On each keystroke: debounces server calls to 300ms
//    3. On disappear / flush: force-save immediately
//

import Foundation
import Combine

@MainActor
final class DailyNoteViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isSaving: Bool = false

    private let email: String
    private let date: Date
    private var saveTask: Task<Void, Never>?

    init(email: String, date: Date) {
        self.email = email
        self.date = date
    }

    // MARK: - Load

    func load() async {
        print("📥 [DailyNoteVM] Loading for \(date)")
        let content = await NouriDailyNotes.shared.fetch(email: email, date: date)
        // Only set if not already populated (prevents overwriting live typing)
        if text.isEmpty {
            text = content
        }
        print("📥 [DailyNoteVM] Load finished. Text length: \(self.text.count)")
    }

    // MARK: - Text Change Handler

    func onTextChanged() {
        print("✍️ [DailyNoteVM] Text changed, resetting debounce...")
        // Reset the debounce timer — server save fires 300ms after last keystroke
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            guard !Task.isCancelled else { 
                print("⏭️ [DailyNoteVM] Debounce cancelled (typing continues)")
                return 
            }
            print("🕒 [DailyNoteVM] Debounce finished, triggering save...")
            await performSave()
        }
    }

    // MARK: - Flush (on disappear / day switch)

    func flush() async {
        print("🚿 [DailyNoteVM] Flushing save for \(date)...")
        saveTask?.cancel()
        await performSave()
    }

    // MARK: - Private

    private func performSave() async {
        guard !email.isEmpty else {
            print("⚠️ [DailyNoteVM] No email — skipping save")
            return
        }
        isSaving = true
        await NouriDailyNotes.shared.saveIfDirty(email: email, date: date, content: text)
        isSaving = false
    }
}
