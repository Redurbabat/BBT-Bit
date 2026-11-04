# Bekannte und behobene Fehler

| ID | Symptom und Ursache | Behebung und Nachweis |
| --- | --- | --- |
| P-001 | Ein iPhone-Bericht zeigte gescheiterte YouTube-Extraktion vor dem ersten Audio-Puffer. Im Apple-Pfad konnte die Client-Suche bei einer Antwort enden, die erst danach am Transport oder der URL-Prüfung scheiterte. Der Bericht enthält keine einzelnen Serverantworten. | Der Reparaturbranch prüft progressive Kandidaten während der Client-Suche, trennt Netzfehler und Abbrüche und begrenzt Hintergrundanfragen. Ein aktueller Live-Nachweis steht in BBT-002 aus. [Analyse und Prüfstand](docs/claude-youtube-playback-handoff-20261104.md#analyse-und-prüfstand-des-reparaturbranches) |
| P-002 | Der Codemagic-Archivbau konnte an der Verlinkung von MusicUnderstanding scheitern. Das verwendete iOS-26-SDK stellte das Framework nicht zur Verlinkung bereit. | [XcodeGen](AppleApp/project.yml) erzwingt die Verlinkung nicht. Der Swift-Code bindet das Framework SDK-abhängig ein. Beleg im Commit `7755430`. |
