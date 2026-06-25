import SwiftUI
import AVFoundation

final class StepSpeaker {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

struct CookingModeView: View {
    let recipe: Recipe
    let chaos: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var speaker = StepSpeaker()
    @AppStorage("cookingSpeakSteps") private var speakSteps = true

    private var steps: [String] { recipe.steps }
    private var stepNumber: Int { index + 1 }
    private var total: Int { steps.count }
    private var isLast: Bool { index >= total - 1 }
    private var currentStep: String { steps.indices.contains(index) ? steps[index] : "" }

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(stepNumber), total: Double(max(total, 1)))
                .tint(Brand.accent)
                .padding()

            Spacer()

            VStack(spacing: 16) {
                Text("Step \(stepNumber) of \(total)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(currentStep)
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal)
                    .accessibilityLabel("Step \(stepNumber) of \(total). \(currentStep)")
            }

            Spacer()

            VStack(spacing: 14) {
                Button { speaker.speak(currentStep) } label: {
                    Label("Repeat Step", systemImage: "arrow.clockwise")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity).padding()
                        .background(Brand.accent.opacity(0.15))
                        .foregroundStyle(Brand.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                HStack(spacing: 14) {
                    Button { previousStep() } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity).padding()
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(index == 0)

                    Button { nextStep() } label: {
                        Label(isLast ? "Done" : "Next Step", systemImage: isLast ? "checkmark" : "chevron.right")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity).padding()
                            .background(Brand.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(recipe.displayName(chaos: chaos))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    speakSteps.toggle()
                    if !speakSteps { speaker.stop() }
                } label: {
                    Image(systemName: speakSteps ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                .accessibilityLabel(speakSteps ? "Mute step narration" : "Unmute step narration")
            }
        }
        .onAppear { announce() }
        .onDisappear { speaker.stop() }
    }

    private func nextStep() {
        if isLast { speaker.stop(); dismiss(); return }
        index += 1
        announce()
    }

    private func previousStep() {
        guard index > 0 else { return }
        index -= 1
        announce()
    }

    private func announce() {
        if speakSteps { speaker.speak(currentStep) }
    }
}
