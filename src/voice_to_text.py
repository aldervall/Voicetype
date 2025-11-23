#!/usr/bin/env python3
"""
Voice-to-Text Input: Record audio, transcribe with whisper.cpp, and type into active window
Cross-platform support for Wayland and X11, multiple desktop environments

Prerequisites:
- whisper.cpp server running on port 2022
- Keyboard automation tool (ydotool, kdotool, or xdotool) - auto-detected
"""
import sys
import subprocess
from .voice_type import VoiceTranscriber, DURATION
from .platform_detect import get_platform_info


def type_text_into_window(text, platform):
    """Type text into the active window using best available tool"""
    if not text:
        print("No text to type")
        return False

    # Try direct typing first
    if platform.type_text(text):
        print(f"\n✓ Typed {len(text)} characters into active window")
        return True

    # Fallback to clipboard if direct typing fails
    print("⚠ Direct typing not available, using clipboard fallback...")
    if platform.copy_to_clipboard(text):
        print(f"✓ Copied {len(text)} characters to clipboard")
        print("📋 Text ready - paste manually with Ctrl+V (or Shift+Ctrl+V for terminals)")
        return True

    print("✗ Error: No typing or clipboard tool available")
    return False


def main():
    """Main function to record, transcribe, and type text"""

    # Detect platform and available tools
    platform = get_platform_info()

    # Check if we have typing or clipboard tools
    if not platform.get_keyboard_tool() and not platform.get_clipboard_tool():
        print("✗ Error: No keyboard automation or clipboard tool available")
        print("\nPlease install required tools:")
        print(platform.get_install_instructions())
        sys.exit(1)

    print("="*60)
    print(f"Voice-to-Text Input ({platform.display_server.upper()}/{platform.desktop_env})")
    print("="*60)
    print(f"Using: {platform.get_keyboard_tool() or 'clipboard'} for text input")
    print("="*60)
    print("\nThis will:")
    print(f"  1. Record audio for {DURATION} seconds")
    print("  2. Transcribe using whisper.cpp")
    print("  3. Type the text into the active window")
    print("\nMake sure Claude Code terminal is focused!")
    print("="*60)

    # Give user time to focus the correct window
    try:
        input("\nPress ENTER when ready to record (or Ctrl+C to cancel): ")
    except KeyboardInterrupt:
        print("\n\nCancelled.")
        sys.exit(0)

    try:
        # Initialize transcriber (checks whisper.cpp connection)
        transcriber = VoiceTranscriber()

        # Record audio
        audio_data = transcriber.record_audio()

        # Transcribe
        transcribed_text = transcriber.transcribe_audio(audio_data)

        if transcribed_text:
            print("\n" + "-"*60)
            print("Transcription:")
            print("-"*60)
            print(transcribed_text)
            print("-"*60)

            # Type into active window
            print("\nTyping into active window...")
            type_text_into_window(transcribed_text, platform)

        else:
            print("\n✗ No speech detected or transcription failed")
            sys.exit(1)

    except KeyboardInterrupt:
        print("\n\nInterrupted. Exiting.")
        sys.exit(0)
    except Exception as e:
        print(f"\n✗ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
