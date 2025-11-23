---
description: Quick voice input - record and transcribe audio to text
---

You are helping the user use voice input with VoiceType.

## Steps

1. **Verify whisper server:** `curl http://127.0.0.1:2022/health`
   - If not running: `systemctl --user start whisper-server`
   - If not installed: Run `/voice-install` first

2. **Inform user:**
   - Focus Claude Code window BEFORE recording
   - Will record for 5 seconds when they press ENTER
   - Transcription will type into active window

3. **Run:** `voicetype-input`

## Troubleshooting

- **No whisper server:** `systemctl --user start whisper-server`
- **No audio device:** `python -c "import sounddevice as sd; print(sd.query_devices())"`
- **Text didn't type:** Check `systemctl --user status ydotool`

## Tip

For continuous voice input, suggest daemon mode: `systemctl --user start voicetype-daemon` (then just hold F12 to record)
