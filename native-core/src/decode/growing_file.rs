//! A file still being written by a download, read as it grows.

use std::fs::File;
use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};
use symphonia::core::io::MediaSource;

/// A file that is still being appended to — sibling `{path}.grow` is created
/// when the first chunk lands, `{path}.complete` when the last range arrives.
/// `{path}.len` holds googlevideo `clen`.
///
/// itag-18 is faststart (moov in the first megabyte). Reporting the full
/// `clen` as a seekable length makes Symphonia's ISOMP4 demuxer seek to the
/// end before probe returns — playback waits for the whole download, which is
/// the opposite of upstream ExoPlayer (start after ~500 ms of buffer). While
/// the file is growing we look like a progressive stream: not seekable, no
/// byte length, reads wait at EOF until `.complete`.
pub(super) struct GrowingFile {
    pub(super) file: File,
    pub(super) path: PathBuf,
    pub(super) declared_len: Option<u64>,
    /// Playback waits for bytes that have not arrived yet. Analysis must not:
    /// a plan that blocks until `.complete` runs at the end of the song, which
    /// is after the blend it was supposed to schedule.
    pub(super) block: bool,
}

impl GrowingFile {
    pub(super) fn is_growing(path: &str) -> bool {
        Path::new(&format!("{path}.grow")).exists()
            && !Path::new(&format!("{path}.complete")).exists()
    }

    pub(super) fn open(path: &str) -> std::io::Result<Self> {
        Self::open_mode(path, true)
    }

    pub(super) fn open_mode(path: &str, block: bool) -> std::io::Result<Self> {
        Self::check_transfer_state(Path::new(path))?;
        let declared_len = std::fs::read_to_string(format!("{path}.len"))
            .ok()
            .and_then(|s| s.trim().parse().ok())
            .filter(|n: &u64| *n > 0);
        Ok(Self {
            file: File::open(path)?,
            path: PathBuf::from(path),
            declared_len,
            block,
        })
    }

    pub(super) fn is_complete(&self) -> bool {
        Path::new(&format!("{}.complete", self.path.display())).exists()
    }

    /// `.complete` beendet auch bei einem Fehler das Warten. Es ist allein kein
    /// Erfolgsnachweis; `.failed` muss als Transportfehler zur Recovery gelangen.
    pub(super) fn check_transfer_state(path: &Path) -> std::io::Result<()> {
        let reason = if Path::new(&format!("{}.failed", path.display())).exists() {
            Some("download failed")
        } else if Path::new(&format!("{}.playback-cancelled", path.display())).exists() {
            Some("playback reader cancelled")
        } else {
            None
        };
        if let Some(reason) = reason {
            return Err(std::io::Error::new(
                std::io::ErrorKind::ConnectionAborted,
                reason,
            ));
        }
        Ok(())
    }

    pub(super) fn wait_for_len(&self, needed: u64) -> std::io::Result<()> {
        let deadline = Instant::now() + Duration::from_secs(120);
        loop {
            // The transport may replace a stalled progressive stream while the
            // mixer is waiting here. Release the reader so queued stop/load can run.
            Self::check_transfer_state(&self.path)?;
            let len = std::fs::metadata(&self.path)?.len();
            if len >= needed {
                return Ok(());
            }
            if self.is_complete() {
                return if len >= needed {
                    Ok(())
                } else {
                    Err(std::io::Error::new(
                        std::io::ErrorKind::UnexpectedEof,
                        "growing file ended short",
                    ))
                };
            }
            if Instant::now() >= deadline {
                return Err(std::io::Error::new(
                    std::io::ErrorKind::TimedOut,
                    "timed out waiting for download",
                ));
            }
            std::thread::sleep(Duration::from_millis(8));
        }
    }
}

impl Read for GrowingFile {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        // Read::read darf eine leere Anfrage nicht von zukünftigem Netzwerk-I/O
        // abhängig machen. Der Demuxer kann solche Anfragen legitim stellen.
        if buf.is_empty() {
            return Ok(0);
        }
        loop {
            Self::check_transfer_state(&self.path)?;
            let pos = self.file.stream_position()?;
            let n = self.file.read(buf)?;
            if n > 0 {
                return Ok(n);
            }
            if self.is_complete() || !self.block {
                return Ok(0);
            }
            let len = std::fs::metadata(&self.path)?.len();
            if len > pos {
                self.file.seek(SeekFrom::Start(pos))?;
                continue;
            }
            self.wait_for_len(pos + 1)?;
            self.file.seek(SeekFrom::Start(pos))?;
        }
    }
}

impl Seek for GrowingFile {
    fn seek(&mut self, pos: SeekFrom) -> std::io::Result<u64> {
        let current = self.file.stream_position()?;
        let on_disk = std::fs::metadata(&self.path)
            .ok()
            .map(|m| m.len())
            .unwrap_or(current);
        let end = if self.is_complete() {
            on_disk
        } else {
            // Progressive: End(0) is "how far have we got", not the eventual
            // clen — answering clen here is what made probe wait for the last byte.
            on_disk
        };
        let target = match pos {
            SeekFrom::Start(offset) => offset as i64,
            SeekFrom::Current(delta) => current as i64 + delta,
            SeekFrom::End(delta) => end as i64 + delta,
        };
        if target < 0 {
            return Err(std::io::Error::new(
                std::io::ErrorKind::InvalidInput,
                "negative seek",
            ));
        }
        let target = target as u64;
        if self.block {
            self.wait_for_len(target)?;
        } else if !self.is_complete() && target > on_disk {
            return Err(std::io::Error::new(
                std::io::ErrorKind::UnexpectedEof,
                "analysis read stopped at the bytes downloaded so far",
            ));
        }
        self.file.seek(SeekFrom::Start(target))
    }
}

impl MediaSource for GrowingFile {
    fn is_seekable(&self) -> bool {
        self.is_complete()
    }

    fn byte_len(&self) -> Option<u64> {
        if self.is_complete() {
            return std::fs::metadata(&self.path)
                .ok()
                .map(|m| m.len())
                .or(self.declared_len);
        }
        // Unknown length until the last range lands — sequential probe of the
        // first megabyte (moov) is enough to start, and Read waits for more.
        None
    }
}

// ---------------------------------------------------------------------------
// Regressionen des progressiven Dateilesers
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicU64, Ordering};

    static NEXT_FIXTURE: AtomicU64 = AtomicU64::new(0);

    struct Fixture(PathBuf);
    impl Fixture {
        fn new(bytes: &[u8]) -> Self {
            let dir = std::env::temp_dir().join(format!(
                "red-bit-growing-{}-{}",
                std::process::id(),
                NEXT_FIXTURE.fetch_add(1, Ordering::Relaxed)
            ));
            std::fs::create_dir_all(&dir).unwrap();
            let fixture = Self(dir.join("audio"));
            std::fs::write(&fixture.0, bytes).unwrap();
            fixture.mark("grow");
            fixture
        }
        fn mark(&self, suffix: &str) {
            std::fs::write(format!("{}.{}", self.0.display(), suffix), []).unwrap();
        }
        fn open(&self) -> GrowingFile {
            GrowingFile::open(self.0.to_str().unwrap()).unwrap()
        }
    }
    impl Drop for Fixture {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(self.0.parent().unwrap());
        }
    }

    #[test]
    fn failed_transfer_is_not_a_clean_end_of_file() {
        let fixture = Fixture::new(&[]);
        let mut reader = fixture.open();
        fixture.mark("failed");
        fixture.mark("complete");
        let error = reader.read(&mut [0u8; 1]).unwrap_err();
        assert_eq!(error.kind(), std::io::ErrorKind::ConnectionAborted);
    }

    #[test]
    fn failed_transfer_does_not_publish_remaining_partial_bytes() {
        let fixture = Fixture::new(&[1, 2, 3]);
        let mut reader = fixture.open();
        fixture.mark("failed");
        fixture.mark("complete");
        assert_eq!(
            reader.read(&mut [0u8; 1]).unwrap_err().kind(),
            std::io::ErrorKind::ConnectionAborted
        );
        assert_eq!(
            reader.wait_for_len(1).unwrap_err().kind(),
            std::io::ErrorKind::ConnectionAborted
        );
    }

    #[test]
    fn empty_read_never_waits_for_the_next_download_chunk() {
        let fixture = Fixture::new(&[]);
        let mut reader = fixture.open();
        let (sent, received) = std::sync::mpsc::channel();
        let task = std::thread::spawn(move || {
            sent.send(reader.read(&mut [])).unwrap();
        });
        let result = received.recv_timeout(Duration::from_secs(1));
        // Auch beim alten Fehler den Leser freigeben, damit kein Testthread hängt.
        fixture.mark("complete");
        task.join().unwrap();
        assert_eq!(result.expect("Leere Leseanfrage wartet auf Download").unwrap(), 0);
    }

    #[test]
    fn successful_completed_transfer_keeps_normal_eof() {
        let fixture = Fixture::new(&[1, 2, 3]);
        fixture.mark("complete");
        let mut reader = fixture.open();
        let mut bytes = Vec::new();
        reader.read_to_end(&mut bytes).unwrap();
        assert_eq!(bytes, [1, 2, 3]);
    }
}
