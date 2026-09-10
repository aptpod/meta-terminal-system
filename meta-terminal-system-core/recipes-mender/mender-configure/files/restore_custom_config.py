#!/usr/bin/python3

import sys
import argparse
import json
import os
import subprocess
import logging
from pathlib import Path

CONFIG_KEY_SPLIT_DELIMITER = "##"

# Parse args
def parse_args():
    parser = argparse.ArgumentParser(description="Restore custom configuration settings")
    parser.add_argument("deployed_config_path", type=str, help="Path to deployed config file")
    parser.add_argument("backup_config_path", type=str, help="Path to backup config file")
    parser.add_argument("--log", type=str, default="INFO", help="Log level")
    parser.add_argument("--terminal-system-config", type=str, default="/usr/lib/mender-configure/terminal-system-config", help="Path to terminal-system-config script")
    return parser.parse_args()

# Only parse args when running as main script, not during import
if __name__ == "__main__":
    args = parse_args()
    # logging setting
    logging.basicConfig(
        level=getattr(logging, args.log.upper()), format="%(levelname)s: %(message)s"
    )
else:
    args = None
    # Set default logging for tests
    logging.basicConfig(
        level=logging.INFO, format="%(levelname)s: %(message)s"
    )


def validate_file_paths():
    if not os.path.exists(args.deployed_config_path):
        logging.error(f"Deployed config file does not exist: {args.deployed_config_path}")
        return False

    if not os.path.exists(args.backup_config_path):
        logging.error(f"Backup config file does not exist: {args.backup_config_path}")
        return False

    return True


def get_base_key_name(key):
    if CONFIG_KEY_SPLIT_DELIMITER in key:
        base_key, suffix = key.rsplit(CONFIG_KEY_SPLIT_DELIMITER, 1)
        if suffix.isdigit():
            return base_key
    return key


def load_json_file(file_path):
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            # Handle null/None values by treating them as empty dict
            if data is None:
                logging.warning(f"JSON file {file_path} contains null value, treating as empty object")
                return {}
            return data
    except json.JSONDecodeError as e:
        logging.error(f"Failed to parse JSON file {file_path}: {e}")
        return None
    except Exception as e:
        logging.error(f"Failed to read file {file_path}: {e}")
        return None


def get_terminal_system_api_keys():
    try:
        terminal_system_config_path = args.terminal_system_config

        if not os.path.exists(terminal_system_config_path):
            logging.error(f"terminal-system-config script not found: {terminal_system_config_path}")
            return None

        # Execute terminal-system-config --list-keys
        result = subprocess.run(
            ["python3", terminal_system_config_path, "--list-keys"],
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode != 0:
            logging.error(f"terminal-system-config failed with return code {result.returncode}")
            logging.error(f"stderr: {result.stderr}")
            return None

        # Parse the JSON output
        api_keys = json.loads(result.stdout.strip())
        logging.debug(f"Retrieved {len(api_keys)} Terminal System API keys")
        return api_keys

    except subprocess.TimeoutExpired:
        logging.error("terminal-system-config --list-keys timed out")
        return None
    except json.JSONDecodeError as e:
        logging.error(f"Failed to parse terminal-system-config output as JSON: {e}")
        logging.error(f"stdout: {result.stdout}")
        return None
    except Exception as e:
        logging.error(f"Failed to get Terminal System API keys: {e}")
        return None


def check_deployed_has_all_api_keys(deployed_config, api_keys):
    if not api_keys:
        logging.warning("No API keys provided for comparison")
        return False

    deployed_base_keys = set(get_base_key_name(k) for k in deployed_config.keys())
    api_keys_set = set(api_keys)

    missing_keys = api_keys_set - deployed_base_keys

    if missing_keys:
        logging.debug(f"Deployed config is missing {len(missing_keys)} API keys: {sorted(missing_keys)}")
        return False
    else:
        logging.debug("Deployed config contains all Terminal System API keys")
        return True


def extract_custom_settings(config, api_keys):
    if not api_keys:
        logging.warning("No API keys provided for filtering")
        return {}

    api_keys_set = set(api_keys)
    custom_settings = {}

    for k, v in config.items():
        base_key = get_base_key_name(k)
        if base_key not in api_keys_set:
            custom_settings[k] = v

    return custom_settings


def find_deleted_custom_settings(backup_custom_settings, deployed_custom_settings):
    backup_keys = set(backup_custom_settings.keys())
    deployed_keys = set(deployed_custom_settings.keys())

    deleted_keys = backup_keys - deployed_keys
    deleted_settings = {k: backup_custom_settings[k] for k in deleted_keys}

    return deleted_settings


def restore_deleted_settings(deployed_config, deleted_settings):
    if not deleted_settings:
        logging.debug("No deleted settings to restore")
        return deployed_config

    restored_config = deployed_config.copy()
    restored_config.update(deleted_settings)

    return restored_config


def save_json_file(file_path, data):
    try:
        with open(file_path, 'w') as f:
            json.dump(data, f, sort_keys=True, indent=2)
        logging.debug(f"Successfully saved config to {file_path}")
        return True
    except Exception as e:
        logging.error(f"Failed to save file {file_path}: {e}")
        return False


def main():
    if not validate_file_paths():
        return 1

    # Load JSON files
    deployed_config = load_json_file(args.deployed_config_path)
    if deployed_config is None:
        return 1

    backup_config = load_json_file(args.backup_config_path)
    if backup_config is None:
        return 1

    logging.debug(f"Loaded deployed config with {len(deployed_config)} keys")
    logging.debug(f"Loaded backup config with {len(backup_config)} keys")

    # Get Terminal System API keys
    api_keys = get_terminal_system_api_keys()
    if api_keys is None:
        logging.error("Failed to get Terminal System API keys")
        return 1

    # Check if deployed config contains all API keys
    has_all_api_keys = check_deployed_has_all_api_keys(deployed_config, api_keys)

    if has_all_api_keys:
        logging.info("Deployed config contains all API keys. No restoration needed.")
        return 0

    # Extract custom settings from both configs
    backup_custom_settings = extract_custom_settings(backup_config, api_keys)
    deployed_custom_settings = extract_custom_settings(deployed_config, api_keys)
    logging.debug(f"Found {len(backup_custom_settings)} custom settings in backup config")
    logging.debug(f"Found {len(deployed_custom_settings)} custom settings in deployed config")

    # Find deleted custom settings
    deleted_settings = find_deleted_custom_settings(backup_custom_settings, deployed_custom_settings)
    logging.debug(f"Found {len(deleted_settings)} deleted custom settings: {sorted(deleted_settings.keys())}")

    if not deleted_settings:
        logging.info("No custom settings were deleted. No restoration needed.")
        return 0

    # Restore deleted settings
    restored_config = restore_deleted_settings(deployed_config, deleted_settings)
    logging.debug(f"Restored {len(deleted_settings)} custom settings")

    # Save the restored config back to the deployed config file
    if save_json_file(args.deployed_config_path, restored_config):
        logging.info("Custom settings restoration completed successfully")
        return 0
    else:
        logging.error("Failed to save restored config")
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
        sys.exit(1)
