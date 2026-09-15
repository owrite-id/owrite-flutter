# Setup Engine Backend Open Voice Neural TTS (SinPo.id / Owrite)

Dokumentasi ini menjelaskan konfigurasi **Backend Engine Server** untuk memproses teks artikel secara simultan/paralel (*asyncio chunking*) menggunakan Python `edge-tts` hingga menghasilkan audio berkecepatan **<3 detik**.

---

## 🏗️ Arsitektur Sistem

```text
┌─────────────────────────┐         HTTP POST /api/tts           ┌──────────────────────────┐
│    Aplikasi Flutter     │ ───────────────────────────────────► │    Server VPS Backend    │
│       (Owrite App)      │ ◄─────────────────────────────────── │  Python edge-tts Engine  │
│  just_audio / audio-    │        Stream / File MP3             └──────────────────────────┘
│        players          │                                                   │
└─────────────────────────┘                                                   │
                                                                 ┌────────────┴─────────────┐
                                                                 │ Disk Cache (.mp3)        │
                                                                 │ Respons Instant (0ms)    │
                                                                 └──────────────────────────┘
```

---

## 🛠️ LANGKAH SETUP VPS BACKEND

### 1. File Python Generator (`generate_tts.py`)
Simpan file berikut di server VPS Anda:

```python
import sys
import asyncio
import os
import edge_tts

def split_text_at_sentences(text, max_chars=500):
    """Pecah teks menjadi potongan 500 karakter di tanda titik agar bisa di-generate secara paralel"""
    if len(text) <= max_chars:
        return [text]

    chunks = []
    remaining = text
    while len(remaining) > max_chars:
        sub = remaining[:max_chars]
        last_period = -1
        for punct in ['. ', '? ', '! ', '.\n']:
            idx = sub.rfind(punct)
            if idx > last_period:
                last_period = idx

        if last_period > 200:
            chunks.append(remaining[:last_period + 1].strip())
            remaining = remaining[last_period + 1:].strip()
        else:
            last_space = sub.rfind(' ')
            if last_space > 200:
                chunks.append(remaining[:last_space].strip())
                remaining = remaining[last_space:].strip()
            else:
                chunks.append(sub.strip())
                remaining = remaining[max_chars:].strip()

    if remaining.strip():
        chunks.append(remaining.strip())
    return chunks

async def generate_chunk(text, voice_id, rate, pitch, output_path):
    try:
        clean_text = text.replace('"', '').replace("'", '').strip()
        if not clean_text: return
        communicate = edge_tts.Communicate(clean_text, voice_id, rate=rate, pitch=pitch)
        await communicate.save(output_path)
    except Exception as e:
        sys.stderr.write(f"Chunk error: {e}\n")

async def main():
    if len(sys.argv) < 4:
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]
    voice_id = sys.argv[3] # id-ID-ArdiNeural atau id-ID-GadisNeural
    rate = sys.argv[4] if len(sys.argv) > 4 else "+10%"
    pitch = sys.argv[5] if len(sys.argv) > 5 else "-2Hz"

    with open(input_path, 'r', encoding='utf-8') as f:
        text = f.read().strip()

    chunks = split_text_at_sentences(text, max_chars=500)

    if len(chunks) == 1:
        communicate = edge_tts.Communicate(chunks[0], voice_id, rate=rate, pitch=pitch)
        await communicate.save(output_path)
    else:
        # Jalankan semua chunk secara bersamaan (paralel)
        chunk_paths = []
        tasks = []
        for i, chunk_text in enumerate(chunks):
            cp = f"{output_path}.chunk_{i}.mp3"
            chunk_paths.append(cp)
            tasks.append(generate_chunk(chunk_text, voice_id, rate, pitch, cp))

        await asyncio.gather(*tasks)

        # Gabungkan potongan MP3 menjadi 1 file utuh
        with open(output_path, 'wb') as outfile:
            for cp in chunk_paths:
                if os.path.exists(cp):
                    with open(cp, 'rb') as infile:
                        outfile.write(infile.read())
                    os.unlink(cp)

if __name__ == "__main__":
    asyncio.run(main())
```

---

### 2. Anchor Tuning Parameters
- **Suara Pria (Ardi):** `Voice ID`: `id-ID-ArdiNeural`, `Rate`: `+10%`, `Pitch`: `-2Hz`
- **Suara Wanita (Gadis):** `Voice ID`: `id-ID-GadisNeural`, `Rate`: `+10%`, `Pitch`: `+0Hz`
