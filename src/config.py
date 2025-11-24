"""
Configuration loader for VoiceType.

Loads user configuration from ~/.config/voicetype/config.toml
Falls back to sensible defaults if no config file exists.
"""

import os

# Try to import tomllib (Python 3.11+) or tomli as fallback
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        tomllib = None


# Key name to evdev code mapping
# These are the evdev ecodes values for common trigger keys
KEY_NAME_MAP = {
    # Function keys F1-F12
    "F1": 59, "F2": 60, "F3": 61, "F4": 62, "F5": 63, "F6": 64,
    "F7": 65, "F8": 66, "F9": 67, "F10": 68, "F11": 87, "F12": 88,
    # Extended function keys F13-F24
    "F13": 183, "F14": 184, "F15": 185, "F16": 186, "F17": 187,
    "F18": 188, "F19": 204, "F20": 205, "F21": 206, "F22": 207,
    "F23": 208, "F24": 209,
    # Special keys
    "PrintScreen": 99, "Pause": 119, "ScrollLock": 70,
}

# Default configuration values
DEFAULT_CONFIG = {
    "daemon": {
        "trigger_key": "F12",
        "min_duration": 0.3,
    },
    "audio": {
        "beep_enabled": True,
        "beep_use_wav_files": True,
        "start_frequency": 800,
        "stop_frequency": 400,
        "beep_duration": 0.1,
    },
    "output": {
        "clipboard_paste_delay": 0.15,
        "notification_preview_length": 50,
        "notification_timeout": 5000,
    },
    "ui": {
        "show_audio_meter": True,
        "meter_width": 20,
        "meter_update_rate": 10,
    },
}


def get_config_path():
    """Get the path to the user's config file."""
    return os.path.expanduser("~/.config/voicetype/config.toml")


def load_config():
    """
    Load configuration from ~/.config/voicetype/config.toml

    Returns a nested dictionary with configuration values.
    Falls back to defaults for any missing values.
    """
    config = _deep_copy_dict(DEFAULT_CONFIG)
    config_path = get_config_path()

    if os.path.exists(config_path) and tomllib is not None:
        try:
            with open(config_path, "rb") as f:
                user_config = tomllib.load(f)
            # Merge user config with defaults
            _merge_dicts(config, user_config)
        except Exception as e:
            print(f"⚠ Warning: Could not load config from {config_path}: {e}")
            print("  Using default configuration")

    return config


def get_trigger_key_code(config):
    """
    Convert the trigger key name from config to evdev key code.

    Args:
        config: Configuration dictionary from load_config()

    Returns:
        Integer evdev key code (e.g., 88 for F12)
    """
    key_name = config.get("daemon", {}).get("trigger_key", "F12")

    # Handle case-insensitive lookup
    key_name_upper = key_name.upper() if isinstance(key_name, str) else "F12"

    # Special handling for function keys (allow "f12" or "F12")
    if key_name_upper.startswith("F") and key_name_upper[1:].isdigit():
        key_name = "F" + key_name_upper[1:]
    else:
        # For other keys, use title case (e.g., "printscreen" -> "PrintScreen")
        key_name = key_name.title().replace(" ", "")

    if key_name not in KEY_NAME_MAP:
        print(f"⚠ Warning: Unknown trigger key '{key_name}', using F12")
        print(f"  Available keys: {', '.join(sorted(KEY_NAME_MAP.keys()))}")
        return KEY_NAME_MAP["F12"]

    return KEY_NAME_MAP[key_name]


def get_available_keys():
    """Return a list of available key names for configuration."""
    return sorted(KEY_NAME_MAP.keys())


def _deep_copy_dict(d):
    """Create a deep copy of a nested dictionary."""
    result = {}
    for key, value in d.items():
        if isinstance(value, dict):
            result[key] = _deep_copy_dict(value)
        else:
            result[key] = value
    return result


def _merge_dicts(base, override):
    """
    Recursively merge override dict into base dict.
    Modifies base in place.
    """
    for key, value in override.items():
        if key in base and isinstance(base[key], dict) and isinstance(value, dict):
            _merge_dicts(base[key], value)
        else:
            base[key] = value


# For convenience, export commonly used values
def get_trigger_key_name(config):
    """Get the human-readable trigger key name from config."""
    return config.get("daemon", {}).get("trigger_key", "F12")
