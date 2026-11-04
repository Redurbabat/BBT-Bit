# Bekannte und behobene Fehler

| ID | Symptom und Ursache | Behebung und Nachweis |
| --- | --- | --- |
| P-001 | Ein iPhone-Bericht zeigte gescheiterte YouTube-Extraktion vor dem ersten Audio-Puffer. Parallele Fehlversuche konnten dabei wiederholt dieselbe Sitzung neu starten. Der genaue serverseitige Auslöser bleibt offen. | Die Recovery begrenzt Sitzungsneustarts und meldet unterscheidbare Fehlerkategorien. Ein aktueller Live-Nachweis steht in BBT-002 aus. [Recovery-Bericht](docs/iphone-youtube-extraction-recovery-20261104.md) |
| P-002 | Der Codemagic-Archivbau konnte an der Verlinkung von MusicUnderstanding scheitern. Das verwendete iOS-26-SDK stellte das Framework nicht zur Verlinkung bereit. | [XcodeGen](AppleApp/project.yml) erzwingt die Verlinkung nicht. Der Swift-Code bindet das Framework SDK-abhängig ein. Beleg im Commit `7755430`. |
