#!/usr/bin/python3

import sys
import argparse
import json
import subprocess
import logging
import os
from pathlib import Path

CONFIG_VALUE_MAX_LENGTH = 4096
CONFIG_KEY_SPLIT_DELIMITER = "##"
MENDER_CONFIGURE_PATH = "/usr/share/mender/modules/v3/mender-configure"
MENDER_INVENTORY_SCRIPT_PATH = "/usr/share/mender/inventory/mender-inventory-mender-configure"
WORK_DIR_DEFAULT = "/data/mender-configure/advanced-settings"

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s",
    stream=sys.stderr,
)


def get_base_key_name(key: str) -> str:
    if CONFIG_KEY_SPLIT_DELIMITER in key:
        base_key, suffix = key.rsplit(CONFIG_KEY_SPLIT_DELIMITER, 1)
        if suffix.isdigit():
            return base_key
    return key


def merge_split_keys(config: dict) -> dict:
    merged = {}

    sorted_keys = sorted(config.keys())

    for key in sorted_keys:
        base_key = get_base_key_name(key)
        if base_key != key:
            if base_key not in merged:
                merged[base_key] = ""
            merged[base_key] += config[key]
        else:
            if key not in merged:
                merged[key] = config[key]

    return merged


def split_long_values(config: dict) -> dict:
    split_config = {}

    for key, value in config.items():
        if isinstance(value, str) and len(value) > CONFIG_VALUE_MAX_LENGTH:
            parts = [
                value[i : i + CONFIG_VALUE_MAX_LENGTH]
                for i in range(0, len(value), CONFIG_VALUE_MAX_LENGTH)
            ]
            for i, part in enumerate(parts):
                split_key = f"{key}{CONFIG_KEY_SPLIT_DELIMITER}{i + 1:010d}"
                split_config[split_key] = part
        else:
            split_config[key] = value

    return split_config


def deserialize_mender_format(config: dict) -> dict:
    result = {}
    for key, value in config.items():
        if isinstance(value, str):
            try:
                result[key] = json.loads(value)
            except json.JSONDecodeError:
                result[key] = value
        else:
            result[key] = value
    return result


def serialize_mender_format(config: dict) -> dict:
    result = {}
    for key, value in config.items():
        if isinstance(value, str):
            result[key] = value
        else:
            result[key] = json.dumps(value, separators=(",", ":"))
    return result


def load_config(config_path: str) -> dict:
    try:
        with open(config_path, "r") as f:
            config = json.load(f)
            if config is None:
                return {}
            return config
    except FileNotFoundError:
        logging.warning(f"Config file not found: {config_path}")
        return {}
    except json.JSONDecodeError as e:
        logging.error(f"Failed to parse config file: {e}")
        raise


def update_device_config() -> bool:
    if not os.path.exists(MENDER_INVENTORY_SCRIPT_PATH):
        logging.warning(f"Inventory script not found: {MENDER_INVENTORY_SCRIPT_PATH}")
        return True

    try:
        env = os.environ.copy()
        env["UPDATE_ONLY"] = "true"
        result = subprocess.run(
            [MENDER_INVENTORY_SCRIPT_PATH],
            capture_output=True,
            text=True,
            env=env,
        )
        if result.returncode != 0:
            logging.error(f"Inventory script failed: {result.stderr}")
            return False
        return True
    except Exception as e:
        logging.error(f"Failed to run inventory script: {e}")
        return False


def do_get(config_path: str, mender_format: bool) -> int:
    try:
        if not update_device_config():
            return 1

        config = load_config(config_path)

        if mender_format:
            output = config
        else:
            config = merge_split_keys(config)
            output = deserialize_mender_format(config)

        print(json.dumps(output, indent=2, ensure_ascii=False))
        return 0

    except Exception as e:
        logging.error(f"GET operation failed: {e}")
        return 1


def prepare_mender_work_dir(work_dir: str, config: dict) -> Path:
    # Create work directory structure expected by mender-configure ArtifactInstall:
    # header/meta-data (input), tmp/needs-reboot (output)
    header_dir = Path(work_dir) / "header"
    tmp_dir = Path(work_dir) / "tmp"

    header_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir.mkdir(parents=True, exist_ok=True)

    meta_data_path = header_dir / "meta-data"
    with open(meta_data_path, "w") as f:
        json.dump(config, f, sort_keys=True, indent=2)

    return tmp_dir


def check_needs_reboot(tmp_dir: Path) -> bool:
    # mender-configure creates needs-reboot file when apply_scripts returns 20
    needs_reboot_file = tmp_dir / "needs-reboot"
    return needs_reboot_file.exists()


def cleanup_work_dir(work_dir: str) -> None:
    try:
        import shutil

        if os.path.exists(work_dir):
            shutil.rmtree(work_dir)
    except Exception:
        pass


def do_put(config_path: str, work_dir: str, mender_format: bool) -> int:
    try:
        input_data = sys.stdin.read()

        try:
            new_config = json.loads(input_data)
        except json.JSONDecodeError as e:
            logging.error(f"Invalid JSON input: {e}")
            return 1

        if not mender_format:
            new_config = serialize_mender_format(new_config)
            new_config = split_long_values(new_config)

        tmp_dir = prepare_mender_work_dir(work_dir, new_config)

        result = subprocess.run(
            [MENDER_CONFIGURE_PATH, "ArtifactInstall", work_dir],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            # Extract ERROR lines from mender-configure stderr (remove nesting/noise)
            error_lines = [
                line.strip()
                for line in result.stderr.strip().split("\n")
                if line.strip().startswith("ERROR:")
            ]
            summary = (
                "\n".join(error_lines) if error_lines else result.stderr.strip()
            )
            sys.stderr.write(summary[:500] + "\n")

            # Rollback silently (don't pollute stderr with rollback errors)
            subprocess.run(
                [MENDER_CONFIGURE_PATH, "ArtifactRollback", work_dir],
                capture_output=True,
                text=True,
            )

            return 1

        reboot_required = check_needs_reboot(tmp_dir)

        result_json = {"reboot_required": reboot_required}
        print(json.dumps(result_json))

        return 0

    except Exception as e:
        logging.error(f"PUT operation failed: {e}")
        return 1
    finally:
        cleanup_work_dir(work_dir)


def main():
    parser = argparse.ArgumentParser(
        description="Get/Put advanced settings (device-config.json) using mender-configure"
    )
    parser.add_argument(
        "operation",
        choices=["get", "put"],
        help="Operation to perform",
    )
    parser.add_argument(
        "config_path",
        help="Path to device-config.json",
    )
    parser.add_argument(
        "work_dir",
        nargs="?",
        default=WORK_DIR_DEFAULT,
        help=f"Working directory for PUT operation (default: {WORK_DIR_DEFAULT})",
    )
    parser.add_argument(
        "--format",
        choices=["mender-configure"],
        dest="format_type",
        help="Data format (default: normal JSON)",
    )
    parser.add_argument(
        "--log",
        default="INFO",
        help="Log level (default: INFO)",
    )

    args = parser.parse_args()

    logging.getLogger().setLevel(getattr(logging, args.log.upper()))

    mender_format = args.format_type == "mender-configure"

    if args.operation == "get":
        return do_get(args.config_path, mender_format)
    elif args.operation == "put":
        return do_put(args.config_path, args.work_dir, mender_format)

    return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
        sys.exit(1)
