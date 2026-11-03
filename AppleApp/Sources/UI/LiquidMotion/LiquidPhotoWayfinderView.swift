#if os(iOS)
import SwiftUI

/// A step-by-step, arrow-based route through the actual BBT-Bit app.
/// It uses the same 15 feature IDs as the real-window screenshot recorder.
private enum PhotoGuideDestination: Equatable {
    case home, player, lyrics, queue, replay, downloads, party
}

private struct PhotoGuideRoute {
    let feature: LiquidPhotoFeature
    let path: [String]
    let takePhotoWhen: String
    let requirement: String?
    let destination: PhotoGuideDestination

    var capturedID: String { String(describing: feature) }

    static let all: [Self] = [
        .init(feature: .island,
              path: ["Startseite öffnen", "Einen Song starten", "Oben Music Island antippen und aufklappen"],
              takePhotoWhen: "Wenn die Music Island mit Albumcover und Steuerung oben sichtbar ist.",
              requirement: "Ein Song muss geladen sein.",
              destination: .home),
        .init(feature: .dock,
              path: ["Vollbild-Player öffnen", "Ganz unten zu „Infinity Dock“ scrollen", "Auf „Lift tools“ tippen, bis EQ / Pipeline / Automix erscheinen"],
              takePhotoWhen: "Wenn alle sechs Tasten des aufgeklappten Infinity Docks sichtbar sind.",
              requirement: "Ein Song muss geladen sein.",
              destination: .player),
        .init(feature: .portal,
              path: ["Vollbild-Player öffnen", "Oben rechts „Warteschlange“ antippen", "Das Glass Portal aufklappen"],
              takePhotoWhen: "Wenn die Vorschau der Warteschlange auf dem echten Player erscheint.",
              requirement: "Mit Songs in der Warteschlange ist mehr zu sehen.",
              destination: .player),
        .init(feature: .lyrics,
              path: ["Vollbild-Player öffnen", "Unten auf Lyrics tippen", "Song mit verfügbarer Übersetzung abspielen"],
              takePhotoWhen: "Wenn Originaltext und Übersetzung in Lyrics Mirror erscheinen.",
              requirement: "Lyrics Mirror erscheint nur bei vorhandener Übersetzung.",
              destination: .lyrics),
        .init(feature: .queue,
              path: ["Vollbild-Player öffnen", "Auf Queue oder das Listen-Symbol tippen", "Die nächsten Songs ansehen"],
              takePhotoWhen: "Wenn Queue Horizon mit den kommenden echten Titeln angezeigt wird.",
              requirement: "Es müssen weitere Titel in der Warteschlange sein.",
              destination: .queue),
        .init(feature: .signal,
              path: ["Vollbild-Player öffnen", "Infinity Dock aufklappen", "Auf Pipeline tippen", "Signal Prism aufklappen"],
              takePhotoWhen: "Wenn die Audio-Pipeline und ihre Verarbeitungskette sichtbar sind.",
              requirement: nil,
              destination: .player),
        .init(feature: .eq,
              path: ["Vollbild-Player öffnen", "Infinity Dock aufklappen", "Auf EQ tippen", "Die EQ-Kurve ansehen"],
              takePhotoWhen: "Wenn EQ Membrane und die Equalizer-Regler sichtbar sind.",
              requirement: nil,
              destination: .player),
        .init(feature: .output,
              path: ["Vollbild-Player öffnen", "Auf Output oder den Kopfhörer-Kreis tippen", "Aktuelle Audioausgabe ansehen"],
              takePhotoWhen: "Wenn Output Halo im Player zu sehen ist.",
              requirement: nil,
              destination: .player),
        .init(feature: .echo,
              path: ["Eine Warteschlange mit mehreren Liedern starten", "Mindestens einen Titel weiterspringen", "Zum Vollbild-Player zurückkehren"],
              takePhotoWhen: "Wenn Echo Trail mit dem vorherigen Titel erscheint.",
              requirement: "Es muss einen vorherigen Titel in der aktuellen Queue geben.",
              destination: .player),
        .init(feature: .automix,
              path: ["Musik abspielen und Automix aktivieren", "Mehrere kompatible Songs in die Queue legen", "Einen echten Automix-Übergang abwarten"],
              takePhotoWhen: "Während Automix Weave tatsächlich einen Übergang anzeigt.",
              requirement: "Der Effekt erscheint nur bei einem echten unterstützten Übergang.",
              destination: .player),
        .init(feature: .canvas,
              path: ["Einen Song mit Canvas-Video auswählen", "Vollbild-Player öffnen", "Albumcover / Canvas anzeigen und die Steuerung öffnen"],
              takePhotoWhen: "Wenn Canvas Veil bei einem echten Canvas-Inhalt erscheint.",
              requirement: "Der Song benötigt eine verfügbare Canvas-Quelle.",
              destination: .player),
        .init(feature: .replay,
              path: ["Bibliothek öffnen", "Auf „Dein Replay“ tippen", "Zur Höraktivität nach Uhrzeit scrollen"],
              takePhotoWhen: "Wenn Replay Time River die tatsächlichen Hörstunden anzeigt.",
              requirement: "Dein iPhone muss bereits Hörstatistiken gesammelt haben.",
              destination: .replay),
        .init(feature: .downloads,
              path: ["Download-Manager öffnen", "Einen Song zum Herunterladen auswählen", "Den Downloadstatus ansehen"],
              takePhotoWhen: "Wenn Download Bloom im Manager bei einem echten Auftrag sichtbar ist.",
              requirement: "Ohne Download-Aufträge erscheint die Anzeige möglicherweise nicht.",
              destination: .downloads),
        .init(feature: .party,
              path: ["„Listen Together“ öffnen", "Eine Party erstellen oder beitreten", "Teilnehmerübersicht ansehen"],
              takePhotoWhen: "Wenn Party Constellation die tatsächlichen verbundenen Teilnehmer anzeigt.",
              requirement: "Für mehrere Teilnehmer sind weitere angemeldete Geräte erforderlich.",
              destination: .party),
        .init(feature: .handoff,
              path: ["BBT-Bit auf zwei kompatiblen Geräten vorbereiten", "Wiedergabe vom zweiten Gerät übergeben", "Die Annahme auf diesem iPhone beobachten"],
              takePhotoWhen: "Genau wenn „Handoff received“ auf dem iPhone erscheint.",
              requirement: "Ein zweites Gerät und eine echte erfolgreiche Übergabe sind erforderlich.",
              destination: .player)
    ]
}

struct LiquidPhotoWayfinderView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(PlaybackController.self) private var playback
    @State private var recorder = LiquidLiveScreenshotRecorder.shared
    @AppStorage("bbt.photoGuide.step") private var currentStep = 0
    @State private var alertText: String?
    @Environment(\.dismiss) private var dismiss

    private var safeIndex: Int {
        min(max(currentStep, 0), PhotoGuideRoute.all.count - 1)
    }

    private var selected: PhotoGuideRoute { PhotoGuideRoute.all[safeIndex] }

    private var capturedCount: Int {
        PhotoGuideRoute.all.filter { hasPhoto($0) }.count
    }

    private func hasPhoto(_ route: PhotoGuideRoute) -> Bool {
        recorder.captures.contains { $0.featureID == route.capturedID }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("FOTO-WEGWEISER", systemImage: "location.north.line.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan)
                        Spacer()
                        Text("\(capturedCount) / 15 Fotos")
                            .font(.caption.monospacedDigit())
                    }

                    ProgressView(value: Double(capturedCount), total: 15)
                        .tint(.cyan)
                    Text("Öffne echte BBT-Bit-Ansichten. Der Recorder fotografiert sichtbare Änderungen automatisch. Fehlende Fotos bleiben offen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if recorder.recording {
                        Label("Automatische echte Screenshots sind aktiviert", systemImage: "record.circle")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            recorder.begin()
                        } label: {
                            Label("Echte Screenshot-Aufnahme starten", systemImage: "camera.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.vertical, 5)
            }

            Section {
                routeCard
            } header: {
                Text("Deine aktuelle Station")
            }

            Section {
                HStack(spacing: 12) {
                    Button {
                        currentStep = max(0, safeIndex - 1)
                    } label: {
                        Label("Zurück", systemImage: "arrow.left")
                    }
                    .disabled(safeIndex == 0)
                    Spacer()
                    Button {
                        currentStep = min(PhotoGuideRoute.all.count - 1, safeIndex + 1)
                    } label: {
                        Label("Weiter", systemImage: "arrow.right")
                            .labelStyle(.titleAndIcon)
                    }
                    .disabled(safeIndex == PhotoGuideRoute.all.count - 1)
                }
                .buttonStyle(.bordered)

                if capturedCount < 15 {
                    Button {
                        if let next = PhotoGuideRoute.all.firstIndex(where: { !hasPhoto($0) }) {
                            currentStep = next
                        }
                    } label: {
                        Label("Zum nächsten fehlenden Foto", systemImage: "arrow.right.to.line")
                    }
                }
            }

            Section("Alle 15 Fotostationen") {
                ForEach(Array(PhotoGuideRoute.all.enumerated()), id: \.element.feature.id) { index, route in
                    Button {
                        currentStep = index
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: hasPhoto(route) ? "checkmark.circle.fill" : "circle.dashed")
                                .foregroundStyle(hasPhoto(route) ? Color.green : Color.secondary)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(String(format: "%02d · %@", index + 1, route.feature.title))
                                    .font(.subheadline.weight(safeIndex == index ? .semibold : .regular))
                                    .foregroundStyle(.primary)
                                Text(route.feature.location)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: safeIndex == index ? "arrow.left.circle.fill" : "chevron.right")
                                .foregroundStyle(safeIndex == index ? Color.cyan : Color.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("bbt.photoGuide.station.\(index + 1)")
                }
            }
        }
        .navigationTitle("Foto-Wegweiser")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Foto-Wegweiser", isPresented: Binding(
            get: { alertText != nil },
            set: { if !$0 { alertText = nil } }
        )) {
            Button("OK") { alertText = nil }
        } message: {
            Text(alertText ?? "")
        }
        .onAppear {
            if let firstMissing = PhotoGuideRoute.all.firstIndex(where: { !hasPhoto($0) }) {
                currentStep = firstMissing
            }
        }
    }

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: "STATION %02d VON 15", safeIndex + 1))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.cyan)
                    Text(selected.feature.title)
                        .font(.title2.weight(.bold))
                    Text(selected.feature.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: hasPhoto(selected) ? "checkmark.seal.fill" : "camera.viewfinder")
                    .font(.title2)
                    .foregroundStyle(hasPhoto(selected) ? Color.green : Color.cyan)
            }

            if hasPhoto(selected) {
                Label("Echter Screenshot bereits gespeichert", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline.weight(.medium))
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(selected.path.enumerated()), id: \.offset) { stepNumber, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(stepNumber + 1)")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .frame(width: 29, height: 29)
                            .background(.cyan.opacity(0.17), in: Circle())
                            .foregroundStyle(.cyan)
                        Text(instruction)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 3)
                        Spacer(minLength: 0)
                    }
                    if stepNumber < selected.path.count - 1 {
                        Image(systemName: "arrow.down")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.cyan)
                            .padding(.leading, 7)
                            .padding(.vertical, 7)
                    }
                }
            }
            .padding(12)
            .background(.cyan.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 8) {
                Label("HIER SOLL DAS FOTO ENTSTEHEN", systemImage: "camera.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.cyan)
                Text(selected.takePhotoWhen)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                if let requirement = selected.requirement {
                    Label(requirement, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                goToSelected()
            } label: {
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                    Text(goLabel)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!recorder.recording)
            .accessibilityIdentifier("bbt.photoGuide.open")
            if !recorder.recording {
                Text("Zuerst oben die Screenshot-Aufnahme starten.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var goLabel: String {
        switch selected.destination {
        case .home: "Zur Startseite"
        case .player, .lyrics, .queue: "Zum Musikplayer"
        case .replay: "Replay öffnen"
        case .downloads: "Download-Manager öffnen"
        case .party: "Listen Together öffnen"
        }
    }

    private func goToSelected() {
        guard recorder.recording else {
            alertText = "Starte zuerst die echte Screenshot-Aufnahme."
            return
        }
        let destination = selected.destination
        if destination == .player || destination == .lyrics || destination == .queue {
            guard playback.current != nil else {
                alertText = "Starte zuerst einen Song. Der Vollbild-Player braucht eine aktuelle Wiedergabe."
                return
            }
        }
        dismiss()
        appModel.settingsPresented = false

        switch destination {
        case .home:
            appModel.nowPlayingPresented = false
            appModel.requestedTab = .home

        case .player, .lyrics, .queue:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                appModel.nowPlayingPresented = true
                if destination == .lyrics || destination == .queue {
                    try? await Task.sleep(for: .milliseconds(650))
                    if destination == .lyrics {
                        appModel.lyricsRevealRequested = true
                    } else {
                        appModel.queueRevealRequested = true
                    }
                }
            }

        case .replay:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                appModel.replayPresented = true
            }

        case .downloads:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                appModel.downloadManagerPresented = true
            }

        case .party:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                appModel.listenTogetherPresented = true
            }
        }
    }
}
#endif
