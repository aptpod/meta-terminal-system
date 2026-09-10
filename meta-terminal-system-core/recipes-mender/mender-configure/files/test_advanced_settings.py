#!/usr/bin/python3

import unittest
from unittest.mock import patch, MagicMock
import json
import os
import tempfile
import shutil

import advanced_settings


class TestGetBaseKeyName(unittest.TestCase):
    def test_split_key(self):
        self.assertEqual(
            advanced_settings.get_base_key_name("device_connectors##0000000001"),
            "device_connectors"
        )
        self.assertEqual(
            advanced_settings.get_base_key_name("custom_setting##0000000002"),
            "custom_setting"
        )

    def test_regular_key(self):
        self.assertEqual(
            advanced_settings.get_base_key_name("regular_key"),
            "regular_key"
        )

    def test_key_with_delimiter_but_not_split(self):
        self.assertEqual(
            advanced_settings.get_base_key_name("key##notanumber"),
            "key##notanumber"
        )


class TestMergeSplitKeys(unittest.TestCase):
    def test_merge_split_keys(self):
        input = {
            "time_sync": '{"ntp_server_pool":"ntp.example.com"}',
            "gps": '{"gps_device":"/dev/ttyTHS1"}',
            "diagnostic_monitors##0000000001": "A" * 4096,
            "diagnostic_monitors##0000000002": "...end]",
            "device_connectors##0000000001": "B" * 4096,
            "device_connectors##0000000002": "B" * 4096,
            "device_connectors##0000000003": "...end]",
        }
        expected = {
            "time_sync": '{"ntp_server_pool":"ntp.example.com"}',
            "gps": '{"gps_device":"/dev/ttyTHS1"}',
            "diagnostic_monitors": "A" * 4096 + "...end]",
            "device_connectors": "B" * 4096 + "B" * 4096 + "...end]",
        }
        result = advanced_settings.merge_split_keys(input)
        self.assertEqual(result, expected)


class TestSplitLongValues(unittest.TestCase):
    def test_split_long_values(self):
        input = {
            "time_sync": '{"ntp_server_pool":"ntp.example.com"}',
            "gps": '{"gps_device":"/dev/ttyTHS1"}',
            "diagnostic_monitors": "A" * 4096 + "...end]",
            "device_connectors": "B" * 4096 + "B" * 4096 + "...end]",
        }
        expected = {
            "time_sync": '{"ntp_server_pool":"ntp.example.com"}',
            "gps": '{"gps_device":"/dev/ttyTHS1"}',
            "diagnostic_monitors##0000000001": "A" * 4096,
            "diagnostic_monitors##0000000002": "...end]",
            "device_connectors##0000000001": "B" * 4096,
            "device_connectors##0000000002": "B" * 4096,
            "device_connectors##0000000003": "...end]",
        }
        result = advanced_settings.split_long_values(input)
        self.assertEqual(result, expected)


class TestFormatConversion(unittest.TestCase):
    def test_deserialize_mender_format(self):
        input = {
            "time_sync": '{"ntp_server_pool":"ntp.example.com","sync_with_gps_pps":true}',
            "gps": '{"gps_device":"/dev/ttyTHS1","speed":57600}',
            "device_connectors": '[{"id":"canfd-1","enabled":true}]',
            "invalid_json": "not valid json",
        }
        expected = {
            "time_sync": {"ntp_server_pool": "ntp.example.com", "sync_with_gps_pps": True},
            "gps": {"gps_device": "/dev/ttyTHS1", "speed": 57600},
            "device_connectors": [{"id": "canfd-1", "enabled": True}],
            "invalid_json": "not valid json",
        }
        result = advanced_settings.deserialize_mender_format(input)
        self.assertEqual(result, expected)

    def test_serialize_mender_format(self):
        input = {
            "time_sync": {"ntp_server_pool": "ntp.example.com", "sync_with_gps_pps": True},
            "gps": {"gps_device": "/dev/ttyTHS1", "speed": 57600},
            "device_connectors": [{"id": "canfd-1", "enabled": True}],
            "string_value": "plain string",
        }
        expected = {
            "time_sync": '{"ntp_server_pool":"ntp.example.com","sync_with_gps_pps":true}',
            "gps": '{"gps_device":"/dev/ttyTHS1","speed":57600}',
            "device_connectors": '[{"id":"canfd-1","enabled":true}]',
            "string_value": "plain string",
        }
        result = advanced_settings.serialize_mender_format(input)
        self.assertEqual(result, expected)


class TestDoGet(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.config_path = os.path.join(self.tmpdir, "device-config.json")

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    @patch("advanced_settings.update_device_config")
    def test_get_success(self, mock_update):
        mock_update.return_value = True
        test_cases = [
            {
                "mender_format": False,
                "input": {"key": '{"enabled":true}'},
                "expected_output": {"key": {"enabled": True}},
            },
            {
                "mender_format": True,
                "input": {"key": '{"enabled":true}'},
                "expected_output": {"key": '{"enabled":true}'},
            },
            {
                "mender_format": False,
                "input": {
                    "key##0000000001": "A" * 4096,
                    "key##0000000002": "B",
                },
                "expected_output": {"key": "A" * 4096 + "B"},
            },
            {
                "mender_format": True,
                "input": {
                    "key##0000000001": "A" * 4096,
                    "key##0000000002": "B",
                },
                "expected_output": {
                    "key##0000000001": "A" * 4096,
                    "key##0000000002": "B",
                },
            },
        ]

        for case in test_cases:
            with self.subTest(mender_format=case["mender_format"], input=list(case["input"].keys())):
                with open(self.config_path, "w") as f:
                    json.dump(case["input"], f)

                with patch("builtins.print") as mock_print:
                    result = advanced_settings.do_get(
                        self.config_path, mender_format=case["mender_format"]
                    )

                self.assertEqual(result, 0)
                output = json.loads(mock_print.call_args[0][0])
                self.assertEqual(output, case["expected_output"])


class TestDoPut(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.config_path = os.path.join(self.tmpdir, "device-config.json")
        self.work_dir = os.path.join(self.tmpdir, "work")
        with open(self.config_path, "w") as f:
            json.dump({}, f)

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    @patch("subprocess.run")
    def test_put_success(self, mock_run):
        test_cases = [
            {
                "mender_format": False,
                "needs_reboot": False,
                "input": {"key": {"enabled": True}},
                "expected_meta_data": {"key": '{"enabled":true}'},
                "expected_output": {"reboot_required": False},
            },
            {
                "mender_format": True,
                "needs_reboot": False,
                "input": {"key": '{"enabled":true}'},
                "expected_meta_data": {"key": '{"enabled":true}'},
                "expected_output": {"reboot_required": False},
            },
            {
                "mender_format": False,
                "needs_reboot": True,
                "input": {"key": "value"},
                "expected_meta_data": {"key": "value"},
                "expected_output": {"reboot_required": True},
            },
        ]

        for case in test_cases:
            with self.subTest(mender_format=case["mender_format"], needs_reboot=case["needs_reboot"]):
                meta_data_content = None

                def make_side_effect(needs_reboot):
                    def side_effect(*args, **kwargs):
                        nonlocal meta_data_content
                        path = os.path.join(self.work_dir, "header", "meta-data")
                        if os.path.exists(path):
                            with open(path) as f:
                                meta_data_content = json.load(f)
                        if needs_reboot:
                            reboot_path = os.path.join(self.work_dir, "tmp", "needs-reboot")
                            os.makedirs(os.path.dirname(reboot_path), exist_ok=True)
                            open(reboot_path, "w").close()
                        return MagicMock(returncode=0, stderr="")
                    return side_effect

                mock_run.side_effect = make_side_effect(case["needs_reboot"])
                input_json = json.dumps(case["input"])

                with patch("sys.stdin", MagicMock(read=MagicMock(return_value=input_json))):
                    with patch("builtins.print") as mock_print:
                        with patch("shutil.rmtree"):
                            result = advanced_settings.do_put(
                                self.config_path, self.work_dir, case["mender_format"]
                            )

                self.assertEqual(result, 0)
                self.assertEqual(meta_data_content, case["expected_meta_data"])
                output = json.loads(mock_print.call_args[0][0])
                self.assertEqual(output, case["expected_output"])

    def test_put_invalid_json(self):
        input = "not a valid json"
        expected_return = 1

        with patch("sys.stdin", MagicMock(read=MagicMock(return_value=input))):
            result = advanced_settings.do_put(
                self.config_path, self.work_dir, mender_format=False
            )

        self.assertEqual(result, expected_return)

    @patch("subprocess.run")
    def test_put_mender_configure_failure(self, mock_run):
        input = {"key": "value"}
        expected_return = 1
        expected_call_count = 2  # ArtifactInstall + ArtifactRollback

        mock_run.return_value = MagicMock(returncode=1, stderr="error")

        with patch("sys.stdin", MagicMock(read=MagicMock(return_value=json.dumps(input)))):
            result = advanced_settings.do_put(
                self.config_path, self.work_dir, mender_format=False
            )

        self.assertEqual(result, expected_return)
        self.assertEqual(mock_run.call_count, expected_call_count)


if __name__ == "__main__":
    unittest.main()
