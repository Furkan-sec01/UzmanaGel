import Foundation
import Speech
import AVFoundation
import Combine

final class SpeechRecognizer: ObservableObject, @unchecked Sendable {

    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    @Published var errorMessage: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// İzin durumunu kontrol et ve iste
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    AVAudioApplication.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if !granted {
                                self?.errorMessage = "Mikrofon izni verilmedi"
                            }
                            completion(granted)
                        }
                    }
                case .denied, .restricted:
                    self?.errorMessage = "Konuşma tanıma izni verilmedi"
                    completion(false)
                case .notDetermined:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    /// Dinlemeyi başlat
    func startListening() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Konuşma tanıma kullanılamıyor"
            return
        }

        // Önceki oturumu temizle
        stopListening()

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Ses oturumu başlatılamadı"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }

                if error != nil || (result?.isFinal ?? false) {
                    self.stopListening()
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.transcript = ""
            }
        } catch {
            errorMessage = "Ses motoru başlatılamadı"
        }

        // 8 saniye sonra otomatik durdur
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            if self?.isListening == true {
                self?.stopListening()
            }
        }
    }

    /// Dinlemeyi durdur
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        DispatchQueue.main.async {
            self.isListening = false
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Toggle: dinliyorsa durdur, dinlemiyorsa başlat
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            requestPermissions { [weak self] granted in
                if granted {
                    self?.startListening()
                }
            }
        }
    }
}
