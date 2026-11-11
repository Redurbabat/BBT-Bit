//! Stimm- und Klangkontur pro Liedtext-Wort für das Lyrics-Sternbild.
//!
//! Pro Wortfenster werden drei Größen aus dem echten Audiosignal gemessen:
//! Lautstärke (RMS in dBFS), Helligkeit (spektraler Schwerpunkt in Hz) und die
//! Grundfrequenz der dominanten periodischen Stimme (YIN-Verfahren) mit einer
//! Konfidenz. Gemessen wird am Gesamtmix, nicht an einer getrennten Gesangsspur:
//! Die Tonhöhe ist deshalb eine Schätzung, die über die Konfidenz ehrlich
//! ausgewiesen wird. Das Sternbild folgt ihr nur, wo sie verlässlich ist, und
//! nimmt sonst die Helligkeit des Klangs.

use super::{fft, hann_window, Complex};
use crate::records::VoiceContourRec;

/// Analyse-Abtastrate: reicht für Stimmgrundtöne bis 800 Hz und Klangfarbe bis 8 kHz.
pub(crate) const CONTOUR_RATE: u32 = 16_000;

const MIN_PITCH_HZ: f64 = 70.0;
const MAX_PITCH_HZ: f64 = 800.0;
const YIN_WINDOW: usize = 640; // 40 ms bei 16 kHz
const YIN_THRESHOLD: f64 = 0.15;
const SPECTRUM_SIZE: usize = 512; // 32 ms bei 16 kHz
const FRAMES_PER_WORD: usize = 4;
const LONGEST_WORD_MS: i64 = 1_500;
const SHORTEST_WORD_MS: i64 = 80;

/// Misst jedes Fenster `[start_ms, end_ms)` im Monosignal `samples` (Abtastrate
/// `rate`). Das Ergebnis hat genau so viele Einträge wie `windows`.
pub(crate) fn measure(samples: &[f32], rate: u32, windows: &[(i64, i64)]) -> Vec<VoiceContourRec> {
    windows
        .iter()
        .map(|&(start, end)| measure_window(samples, rate, start, end))
        .collect()
}

fn silent() -> VoiceContourRec {
    VoiceContourRec { energy_db: -120.0, brightness_hz: 0.0, pitch_hz: 0.0, pitch_confidence: 0.0 }
}

fn measure_window(samples: &[f32], rate: u32, start_ms: i64, end_ms: i64) -> VoiceContourRec {
    if rate == 0 || samples.is_empty() {
        return silent();
    }
    let start_ms = start_ms.max(0);
    // Lange gehaltene Wörter zählen ab ihrem Einsatz; sehr kurze erhalten ein
    // Mindestfenster, damit überhaupt eine Periode messbar ist.
    let end_ms = end_ms.clamp(start_ms + SHORTEST_WORD_MS, start_ms + LONGEST_WORD_MS);
    let to_index = |ms: i64| ((ms as f64 / 1000.0) * rate as f64) as usize;
    let first = to_index(start_ms).min(samples.len());
    let last = to_index(end_ms).min(samples.len());
    if last <= first {
        return silent();
    }
    let window = &samples[first..last];

    let mean_square = window.iter().map(|&s| (s as f64) * (s as f64)).sum::<f64>() / window.len() as f64;
    let energy_db = (20.0 * (mean_square.sqrt() + 1e-9).log10()).max(-120.0);

    // Mehrere Messpunkte über das Wort verteilt; ein einzelner Rahmen würde
    // bei einem Konsonanten am Wortanfang die Stimme verfehlen.
    let mut brightness = Vec::with_capacity(FRAMES_PER_WORD);
    let mut pitches = Vec::with_capacity(FRAMES_PER_WORD);
    let mut confidences = Vec::with_capacity(FRAMES_PER_WORD);
    for frame in 0..FRAMES_PER_WORD {
        let centre = first + (last - first) * (2 * frame + 1) / (2 * FRAMES_PER_WORD);
        if let Some(value) = spectral_centroid(samples, rate, centre) {
            brightness.push(value);
        }
        if let Some((pitch, confidence)) = yin_pitch(samples, rate, centre) {
            pitches.push(pitch);
            confidences.push(confidence);
        }
    }
    let brightness_hz = if brightness.is_empty() { 0.0 } else { brightness.iter().sum::<f64>() / brightness.len() as f64 };

    // Median der stimmhaften Rahmen; die Konfidenz sinkt mit dem Anteil der
    // Rahmen, in denen gar keine Periode gefunden wurde.
    let (pitch_hz, pitch_confidence) = if pitches.is_empty() {
        (0.0, 0.0)
    } else {
        let mut sorted = pitches.clone();
        sorted.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        let median = sorted[sorted.len() / 2];
        let voiced_share = pitches.len() as f64 / FRAMES_PER_WORD as f64;
        let mean_confidence = confidences.iter().sum::<f64>() / confidences.len() as f64;
        (median, (mean_confidence * voiced_share).clamp(0.0, 1.0))
    };

    VoiceContourRec {
        energy_db: energy_db as f32,
        brightness_hz: brightness_hz as f32,
        pitch_hz: pitch_hz as f32,
        pitch_confidence: pitch_confidence as f32,
    }
}

/// Spektraler Schwerpunkt eines Hann-gefensterten Rahmens um `centre`.
fn spectral_centroid(samples: &[f32], rate: u32, centre: usize) -> Option<f64> {
    let half = SPECTRUM_SIZE / 2;
    if centre < half || centre + half > samples.len() {
        return None;
    }
    let window = hann_window(SPECTRUM_SIZE);
    let mut bins: Vec<Complex> = (0..SPECTRUM_SIZE)
        .map(|i| Complex { re: samples[centre - half + i] as f64 * window[i], im: 0.0 })
        .collect();
    fft(&mut bins);
    let bin_hz = rate as f64 / SPECTRUM_SIZE as f64;
    let mut weighted = 0.0;
    let mut total = 0.0;
    for (index, bin) in bins.iter().enumerate().take(half).skip(1) {
        let magnitude = (bin.re * bin.re + bin.im * bin.im).sqrt();
        weighted += magnitude * index as f64 * bin_hz;
        total += magnitude;
    }
    (total > 1e-9).then(|| weighted / total)
}

/// YIN-Grundfrequenz (de Cheveigné & Kawahara 2002) mit parabolischer
/// Verfeinerung. Liefert `None`, wenn das Signal dort zu leise ist.
fn yin_pitch(samples: &[f32], rate: u32, centre: usize) -> Option<(f64, f64)> {
    let min_lag = (rate as f64 / MAX_PITCH_HZ).floor().max(2.0) as usize;
    let max_lag = (rate as f64 / MIN_PITCH_HZ).ceil() as usize;
    let needed = YIN_WINDOW + max_lag + 1;
    let begin = centre.checked_sub(needed / 2)?;
    if begin + needed > samples.len() {
        return None;
    }
    let frame = &samples[begin..begin + needed];
    let power = frame[..YIN_WINDOW].iter().map(|&s| (s as f64).powi(2)).sum::<f64>() / YIN_WINDOW as f64;
    if power < 1e-7 {
        return None;
    }

    let mut difference = vec![0.0f64; max_lag + 1];
    for lag in 1..=max_lag {
        let mut sum = 0.0;
        for j in 0..YIN_WINDOW {
            let delta = frame[j] as f64 - frame[j + lag] as f64;
            sum += delta * delta;
        }
        difference[lag] = sum;
    }
    // Kumulativ normierte Differenz d'(τ).
    let mut normalized = vec![1.0f64; max_lag + 1];
    let mut running = 0.0;
    for lag in 1..=max_lag {
        running += difference[lag];
        normalized[lag] = if running > 0.0 { difference[lag] * lag as f64 / running } else { 1.0 };
    }

    // Erstes Minimum unter der Schwelle, sonst das globale Minimum.
    let mut chosen = None;
    let mut lag = min_lag;
    while lag < max_lag {
        if normalized[lag] < YIN_THRESHOLD {
            while lag + 1 < max_lag && normalized[lag + 1] < normalized[lag] {
                lag += 1;
            }
            chosen = Some(lag);
            break;
        }
        lag += 1;
    }
    let lag = chosen.unwrap_or_else(|| {
        (min_lag..max_lag)
            .min_by(|&a, &b| normalized[a].partial_cmp(&normalized[b]).unwrap_or(std::cmp::Ordering::Equal))
            .unwrap_or(min_lag)
    });

    let refined = if lag > min_lag && lag + 1 < max_lag {
        let (left, mid, right) = (normalized[lag - 1], normalized[lag], normalized[lag + 1]);
        let denominator = left - 2.0 * mid + right;
        if denominator.abs() > 1e-12 { lag as f64 + 0.5 * (left - right) / denominator } else { lag as f64 }
    } else {
        lag as f64
    };
    if refined <= 0.0 {
        return None;
    }
    let confidence = (1.0 - normalized[lag]).clamp(0.0, 1.0);
    Some((rate as f64 / refined, confidence))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::f64::consts::PI;

    fn tone(seconds: f64, rate: u32, sample: impl Fn(f64) -> f64) -> Vec<f32> {
        (0..(seconds * rate as f64) as usize).map(|i| sample(i as f64 / rate as f64) as f32).collect()
    }

    /// Deterministisches Rauschen ohne Zufallsabhängigkeit.
    fn noise(seconds: f64, rate: u32, amplitude: f64) -> Vec<f32> {
        let mut state = 0x2545_F491_4F6C_DD1Du64;
        (0..(seconds * rate as f64) as usize)
            .map(|_| {
                state ^= state << 13;
                state ^= state >> 7;
                state ^= state << 17;
                (((state >> 11) as f64 / (1u64 << 53) as f64) * 2.0 - 1.0) as f32 * amplitude as f32
            })
            .collect()
    }

    fn rate() -> u32 { CONTOUR_RATE }

    #[test]
    fn pitch_follows_the_sung_fundamental() {
        let mut signal = tone(1.0, rate(), |t| 0.1 * (2.0 * PI * 220.0 * t).sin());
        signal.extend(tone(1.0, rate(), |t| 0.5 * (2.0 * PI * 440.0 * t).sin()));
        let result = measure(&signal, rate(), &[(100, 900), (1100, 1900)]);
        assert!((result[0].pitch_hz - 220.0).abs() < 220.0 * 0.03, "220 Hz gemessen als {}", result[0].pitch_hz);
        assert!((result[1].pitch_hz - 440.0).abs() < 440.0 * 0.03, "440 Hz gemessen als {}", result[1].pitch_hz);
        assert!(result[0].pitch_confidence > 0.8 && result[1].pitch_confidence > 0.8);
    }

    #[test]
    fn a_voice_with_harmonics_keeps_its_fundamental_not_an_octave() {
        // Stimmähnlich: Grundton 300 Hz plus kräftige Obertöne.
        let signal = tone(1.0, rate(), |t| {
            let w = 2.0 * PI * 300.0 * t;
            0.30 * w.sin() + 0.25 * (2.0 * w).sin() + 0.15 * (3.0 * w).sin() + 0.08 * (4.0 * w).sin()
        });
        let result = measure(&signal, rate(), &[(100, 900)]);
        assert!((result[0].pitch_hz - 300.0).abs() < 300.0 * 0.03, "Oktavfehler: {}", result[0].pitch_hz);
    }

    #[test]
    fn loudness_difference_is_reported_in_decibels() {
        let mut signal = tone(1.0, rate(), |t| 0.1 * (2.0 * PI * 220.0 * t).sin());
        signal.extend(tone(1.0, rate(), |t| 0.5 * (2.0 * PI * 220.0 * t).sin()));
        let result = measure(&signal, rate(), &[(100, 900), (1100, 1900)]);
        let difference = result[1].energy_db - result[0].energy_db;
        let expected = 20.0 * (5.0f32).log10(); // ≈ 13,98 dB
        assert!((difference - expected).abs() < 0.5, "Pegelunterschied {difference} statt {expected}");
    }

    #[test]
    fn noise_is_bright_and_unpitched() {
        let mut signal = tone(1.0, rate(), |t| 0.3 * (2.0 * PI * 220.0 * t).sin());
        signal.extend(noise(1.0, rate(), 0.3));
        let result = measure(&signal, rate(), &[(100, 900), (1100, 1900)]);
        assert!(result[1].brightness_hz > result[0].brightness_hz * 4.0,
            "Rauschen {} Hz nicht heller als Ton {} Hz", result[1].brightness_hz, result[0].brightness_hz);
        assert!(result[1].pitch_confidence < 0.5, "Rauschen bekam Tonhöhenkonfidenz {}", result[1].pitch_confidence);
    }

    #[test]
    fn silence_and_out_of_range_windows_stay_neutral() {
        let signal = vec![0.0f32; rate() as usize];
        let result = measure(&signal, rate(), &[(100, 900), (5_000, 6_000), (-50, -10)]);
        assert_eq!(result.len(), 3);
        assert!(result.iter().all(|r| r.pitch_confidence == 0.0 && r.pitch_hz == 0.0));
        assert!(result[0].energy_db <= -100.0);
    }

    /// Stereo-Float-WAV wie in den Wiedergabetests; 44,1 kHz zwingt den Export
    /// durch den echten Decoder und die Umrechnung auf 16 kHz.
    fn write_wav(name: &str, seconds: f64, sample: impl Fn(f64) -> f32) -> std::path::PathBuf {
        let path = std::env::temp_dir().join(format!("bitchord-voice-{}-{name}.wav", std::process::id()));
        let rate = 44_100u32;
        let frames = (seconds * rate as f64) as usize;
        let length = frames as u32 * 8;
        let mut bytes = Vec::new();
        bytes.extend(b"RIFF");
        bytes.extend((36 + length).to_le_bytes());
        bytes.extend(b"WAVEfmt ");
        bytes.extend(16u32.to_le_bytes());
        bytes.extend(3u16.to_le_bytes());
        bytes.extend(2u16.to_le_bytes());
        bytes.extend(rate.to_le_bytes());
        bytes.extend((rate * 8).to_le_bytes());
        bytes.extend(8u16.to_le_bytes());
        bytes.extend(32u16.to_le_bytes());
        bytes.extend(b"data");
        bytes.extend(length.to_le_bytes());
        for i in 0..frames {
            let value = sample(i as f64 / rate as f64);
            bytes.extend(value.to_le_bytes());
            bytes.extend(value.to_le_bytes());
        }
        std::fs::write(&path, bytes).unwrap();
        path
    }

    #[test]
    fn the_export_decodes_a_real_file_and_follows_the_melody() {
        let path = write_wav("melody", 2.0, |t| {
            let hz = if t < 1.0 { 220.0 } else { 330.0 };
            (0.3 * (2.0 * PI * hz * t).sin()) as f32
        });
        let result = crate::api::lyric_voice_contour(
            path.to_string_lossy().into_owned(), vec![100, 1100], vec![900, 1900]);
        std::fs::remove_file(&path).ok();
        assert_eq!(result.len(), 2);
        assert!((result[0].pitch_hz - 220.0).abs() < 220.0 * 0.03, "erste Note {}", result[0].pitch_hz);
        assert!((result[1].pitch_hz - 330.0).abs() < 330.0 * 0.03, "zweite Note {}", result[1].pitch_hz);
        assert!(result[1].pitch_hz > result[0].pitch_hz, "die Melodie steigt");
    }

    #[test]
    fn the_export_stays_empty_for_unusable_input() {
        let missing = crate::api::lyric_voice_contour("/nonexistent/song.m4a".into(), vec![0], vec![500]);
        assert!(missing.is_empty());
        let mismatched = crate::api::lyric_voice_contour("/nonexistent/song.m4a".into(), vec![0, 1], vec![500]);
        assert!(mismatched.is_empty());
        let nothing = crate::api::lyric_voice_contour("/nonexistent/song.m4a".into(), vec![], vec![]);
        assert!(nothing.is_empty());
        // Ein Stream-URL wird nie für die Darstellung erneut geladen.
        let remote = crate::api::lyric_voice_contour("https://127.0.0.1:9/song.m4a".into(), vec![0], vec![500]);
        assert!(remote.is_empty());
    }

    #[test]
    fn every_window_gets_exactly_one_result() {
        let signal = tone(2.0, rate(), |t| 0.2 * (2.0 * PI * 330.0 * t).sin());
        let windows: Vec<(i64, i64)> = (0..17).map(|i| (i * 100, i * 100 + 90)).collect();
        assert_eq!(measure(&signal, rate(), &windows).len(), windows.len());
    }
}
