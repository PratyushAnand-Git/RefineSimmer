import AVFoundation
import Observation

/// Fully offline Voice Cooking Assistant using on-device AVSpeechSynthesizer
@Observable
class VoiceCookingAssistant: NSObject, AVSpeechSynthesizerDelegate {

    // MARK: - State

    var isEnabled: Bool = true
    var isSpeaking: Bool = false

    /// Called when the step announcement finishes — ViewModel uses this to auto-start timer
    var onStepAnnouncementCompleted: (() -> Void)?

    private let synthesizer = AVSpeechSynthesizer()
    private var spokenHintForStep: Int = -1
    private var spoken10sAlert: Bool = false
    private var spoken1minAlert: Bool = false
    private var isStepAnnouncement: Bool = false  // Track if current speech is the step announcement

    // Actions that should NOT get voice (non-cooking)
    private let silentActions: Set<CookingAction> = [.prep, .mix, .serve]

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silently fail — voice is non-critical
        }
    }

    // MARK: - Public API

    /// Called when a new step starts — always re-announces (no duplicate guard)
    func announceStep(index: Int, instruction: String, action: CookingAction, durationSeconds: Int?) {
        // Reset per-step tracking
        spokenHintForStep = -1
        spoken10sAlert = false
        spoken1minAlert = false

        guard isEnabled else {
            // Even if voice disabled, fire callback so timer starts
            onStepAnnouncementCompleted?()
            return
        }

        // Non-cooking steps still get read aloud
        let stepNumber = index + 1
        var text = "Step \(stepNumber). "
        text += instruction

        if let duration = durationSeconds, duration > 0 {
            text += " for \(formatDuration(duration))."
        }

        isStepAnnouncement = true
        speak(text)
    }

    /// Called every timer tick — checks for alerts
    func timerTick(
        stepIndex: Int,
        timeRemaining: Int,
        totalDuration: Int,
        isTimerRunning: Bool,
        action: CookingAction
    ) {
        guard isEnabled, isTimerRunning else { return }

        // Context-aware hint: 5-10 seconds after timer starts (speak once)
        let elapsed = totalDuration - timeRemaining
        if elapsed >= 5 && elapsed <= 10 && spokenHintForStep != stepIndex {
            spokenHintForStep = stepIndex
            if let hint = contextHint(for: action) {
                speak(hint)
            }
        }

        // 1 minute remaining (only for durations > 5 min)
        if totalDuration > 300 && timeRemaining == 60 && !spoken1minAlert {
            spoken1minAlert = true
            speak("One minute remaining.")
        }

        // 10 seconds remaining
        if timeRemaining == 10 && !spoken10sAlert {
            spoken10sAlert = true
            speak("10 seconds remaining.")
        }

        // Last 5 seconds countdown: 5, 4, 3, 2, 1
        if timeRemaining >= 1 && timeRemaining <= 5 {
            speakQuick("\(timeRemaining)")
        }

        // Step complete
        if timeRemaining == 0 {
            speak("Step complete.")
        }
    }

    /// Called when user changes heat mid-step
    func announceHeatChange(newHeat: HeatLevel, newRemainingSeconds: Int) {
        guard isEnabled else { return }

        stopSpeaking()
        let text = "Heat changed to \(newHeat.label). New remaining time: \(formatDuration(newRemainingSeconds))."
        speak(text)
    }

    /// Stop speaking immediately (called on skip, pause, heat change)
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isStepAnnouncement = false
    }

    /// Reset state for a new step
    func resetForStep() {
        spoken10sAlert = false
        spoken1minAlert = false
        spokenHintForStep = -1
    }

    // MARK: - Context-Aware Hints

    private func contextHint(for action: CookingAction) -> String? {
        switch action {
        case .boil:
            return "You should start seeing bubbles forming. Maintain steady heat."
        case .simmer:
            return "You should see gentle bubbles, not a rolling boil."
        case .fry, .stirFry:
            return "Listen for a light sizzling sound. Avoid burning."
        case .steam:
            return "Steam should be consistently rising from the pot."
        case .cook:
            return "Stir occasionally to prevent sticking."
        case .heat:
            return "Do not let it smoke."
        case .bake:
            return "Ensure your oven has preheated fully."
        case .grill:
            return "Watch for even browning on both sides."
        default:
            return nil
        }
    }

    // MARK: - TTS Core

    private func speak(_ text: String) {
        // Stop any current speech to avoid overlap
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.05
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    /// Quick speech for countdown numbers — fast, no delay
    private func speakQuick(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.2  // Faster for countdown
        utterance.pitchMultiplier = 1.1
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0

        isStepAnnouncement = false  // Countdown is never a step announcement
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60

        if mins == 0 {
            return "\(secs) seconds"
        } else if secs == 0 {
            return mins == 1 ? "1 minute" : "\(mins) minutes"
        } else {
            let minPart = mins == 1 ? "1 minute" : "\(mins) minutes"
            let secPart = secs == 1 ? "1 second" : "\(secs) seconds"
            return "\(minPart) \(secPart)"
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let wasStepAnnouncement = self.isStepAnnouncement
            self.isSpeaking = false
            self.isStepAnnouncement = false

            // If the step announcement just finished, trigger auto-start timer
            if wasStepAnnouncement {
                self.onStepAnnouncementCompleted?()
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            self?.isStepAnnouncement = false
        }
    }
}
