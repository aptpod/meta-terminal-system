#!/usr/bin/python3

import json
import unittest
import tempfile
import os
from unittest.mock import patch, MagicMock
from restore_custom_config import (
    validate_file_paths,
    load_json_file,
    get_terminal_system_api_keys,
    check_deployed_has_all_api_keys,
    extract_custom_settings,
    find_deleted_custom_settings,
    restore_deleted_settings,
    save_json_file,
    get_base_key_name
)


class TestRestoreCustomConfig(unittest.TestCase):

    def setUp(self):
        # Create temporary test files
        self.test_deployed_config = {
            "network_connections": '{"interfaces": []}',
            "agent.connection": '{"server": "localhost"}'
        }

        self.test_backup_config = {
            "network_connections": '{"interfaces": []}',
            "agent.connection": '{"server": "localhost"}',
            "custom_setting1": '{"value": "test1"}',
            "custom_setting2": '{"value": "test2"}'
        }

        # Create temporary files
        with tempfile.NamedTemporaryFile('w', delete=False) as f:
            json.dump(self.test_deployed_config, f)
            self.deployed_config_path = f.name

        with tempfile.NamedTemporaryFile('w', delete=False) as f:
            json.dump(self.test_backup_config, f)
            self.backup_config_path = f.name

    def tearDown(self):
        # Clean up temporary files
        if os.path.exists(self.deployed_config_path):
            os.remove(self.deployed_config_path)
        if os.path.exists(self.backup_config_path):
            os.remove(self.backup_config_path)

    @patch('restore_custom_config.args')
    def test_validate_file_paths(self, mock_args):
        """Test file path validation scenarios"""
        # Test success case
        mock_args.deployed_config_path = self.deployed_config_path
        mock_args.backup_config_path = self.backup_config_path
        self.assertTrue(validate_file_paths())

        # Test missing deployed config
        mock_args.deployed_config_path = "/nonexistent/path"
        self.assertFalse(validate_file_paths())

        # Test missing backup config
        mock_args.deployed_config_path = self.deployed_config_path
        mock_args.backup_config_path = "/nonexistent/path"
        self.assertFalse(validate_file_paths())

    def test_load_json_file(self):
        """Test JSON file loading scenarios"""
        # Test successful loading
        with self.subTest(scenario="success"):
            result = load_json_file(self.deployed_config_path)
            self.assertIsNotNone(result)
            self.assertEqual(result, self.test_deployed_config)

        # Test nonexistent file
        with self.subTest(scenario="nonexistent"):
            result = load_json_file("/nonexistent/path")
            self.assertIsNone(result)

        # Test invalid JSON
        with self.subTest(scenario="invalid_json"):
            with tempfile.NamedTemporaryFile('w', delete=False) as f:
                f.write("invalid json content")
                invalid_json_path = f.name
            try:
                result = load_json_file(invalid_json_path)
                self.assertIsNone(result)
            finally:
                os.remove(invalid_json_path)

        # Test empty JSON object
        with self.subTest(scenario="empty_object"):
            empty_config = {}
            with tempfile.NamedTemporaryFile('w', delete=False) as f:
                json.dump(empty_config, f)
                empty_json_path = f.name
            try:
                result = load_json_file(empty_json_path)
                self.assertIsNotNone(result)
                self.assertEqual(result, {})
                self.assertIsInstance(result, dict)
                self.assertEqual(len(result), 0)
            finally:
                os.remove(empty_json_path)

        # Test null JSON content
        with self.subTest(scenario="null_content"):
            with tempfile.NamedTemporaryFile('w', delete=False) as f:
                f.write("null")
                null_json_path = f.name
            try:
                result = load_json_file(null_json_path)
                self.assertIsNotNone(result)
                self.assertEqual(result, {})
                self.assertIsInstance(result, dict)
                self.assertEqual(len(result), 0)
            finally:
                os.remove(null_json_path)

    @patch('restore_custom_config.subprocess.run')
    @patch('restore_custom_config.args')
    def test_get_terminal_system_api_keys(self, mock_args, mock_run):
        """Test API key retrieval scenarios"""
        expected_keys = ["network_connections", "agent.connection", "agent.transport"]
        mock_args.terminal_system_config = "/test/path/terminal-system-config"

        # Test successful retrieval
        with self.subTest(scenario="success"):
            mock_result = MagicMock()
            mock_result.returncode = 0
            mock_result.stdout = json.dumps(expected_keys)
            mock_run.return_value = mock_result

            with patch('restore_custom_config.os.path.exists', return_value=True):
                result = get_terminal_system_api_keys()
                self.assertEqual(result, expected_keys)

                # Verify subprocess was called correctly
                call_args = mock_run.call_args[0][0]
                self.assertEqual(call_args[0], "python3")
                self.assertEqual(call_args[1], "/test/path/terminal-system-config")
                self.assertEqual(call_args[2], "--list-keys")

        # Test failure case
        with self.subTest(scenario="failure"):
            mock_result = MagicMock()
            mock_result.returncode = 1
            mock_result.stderr = "Error message"
            mock_run.return_value = mock_result

            with patch('restore_custom_config.os.path.exists', return_value=True):
                result = get_terminal_system_api_keys()
                self.assertIsNone(result)

        # Test invalid JSON
        with self.subTest(scenario="invalid_json"):
            mock_result = MagicMock()
            mock_result.returncode = 0
            mock_result.stdout = "invalid json"
            mock_run.return_value = mock_result

            with patch('restore_custom_config.os.path.exists', return_value=True):
                result = get_terminal_system_api_keys()
                self.assertIsNone(result)

        # Test file not found
        with self.subTest(scenario="file_not_found"):
            result = get_terminal_system_api_keys()
            self.assertIsNone(result)

    def test_check_deployed_has_all_api_keys(self):
        """Test API key presence checking scenarios"""
        # Test complete API keys
        with self.subTest(scenario="complete"):
            deployed_config = {
                "network_connections": '{"test": "value"}',
                "agent.connection": '{"test": "value"}',
                "agent.transport": '{"test": "value"}'
            }
            api_keys = ["network_connections", "agent.connection", "agent.transport"]
            result = check_deployed_has_all_api_keys(deployed_config, api_keys)
            self.assertTrue(result)

        # Test missing API keys
        with self.subTest(scenario="missing"):
            deployed_config = {
                "network_connections": '{"test": "value"}',
                "custom_setting": '{"test": "value"}'
            }
            api_keys = ["network_connections", "agent.connection", "agent.transport"]
            result = check_deployed_has_all_api_keys(deployed_config, api_keys)
            self.assertFalse(result)

        # Test no API keys provided
        with self.subTest(scenario="no_api_keys"):
            deployed_config = {"test": "value"}
            api_keys = []
            result = check_deployed_has_all_api_keys(deployed_config, api_keys)
            self.assertFalse(result)

        # Test with split keys (## delimiter)
        with self.subTest(scenario="split_keys_complete"):
            deployed_config = {
                "network_connections": '{"test": "value"}',
                "device_connectors##0000000001": '{"part": "1"}',
                "device_connectors##0000000002": '{"part": "2"}'
            }
            api_keys = ["network_connections", "device_connectors"]
            result = check_deployed_has_all_api_keys(deployed_config, api_keys)
            self.assertTrue(result)

        # Test with only split keys (no base key present)
        with self.subTest(scenario="only_split_keys"):
            deployed_config = {
                "device_connectors##0000000001": '{"part": "1"}',
                "device_connectors##0000000002": '{"part": "2"}'
            }
            api_keys = ["device_connectors"]
            result = check_deployed_has_all_api_keys(deployed_config, api_keys)
            self.assertTrue(result)

    def test_extract_custom_settings(self):
        """Test custom settings extraction scenarios"""
        # Test with custom settings
        with self.subTest(scenario="with_customs"):
            config = {
                "network_connections": '{"test": "value"}',
                "agent.connection": '{"test": "value"}',
                "custom_setting1": '{"custom": "value1"}',
                "custom_setting2": '{"custom": "value2"}'
            }
            api_keys = ["network_connections", "agent.connection"]
            result = extract_custom_settings(config, api_keys)
            expected = {
                "custom_setting1": '{"custom": "value1"}',
                "custom_setting2": '{"custom": "value2"}'
            }
            self.assertEqual(result, expected)

        # Test with no custom settings
        with self.subTest(scenario="no_customs"):
            config = {
                "network_connections": '{"test": "value"}',
                "agent.connection": '{"test": "value"}'
            }
            api_keys = ["network_connections", "agent.connection"]
            result = extract_custom_settings(config, api_keys)
            self.assertEqual(result, {})

        # Test with no API keys
        with self.subTest(scenario="no_api_keys"):
            config = {"test": "value"}
            api_keys = []
            result = extract_custom_settings(config, api_keys)
            self.assertEqual(result, {})

        # Test empty config
        with self.subTest(scenario="empty_config"):
            empty_config = {}
            api_keys = ["network_connections", "agent.connection"]
            result = extract_custom_settings(empty_config, api_keys)
            self.assertEqual(result, {})
            self.assertEqual(len(result), 0)

    def test_find_deleted_custom_settings(self):
        """Test deleted custom settings detection scenarios"""
        # Test with deletions
        with self.subTest(scenario="with_deletions"):
            backup_custom = {
                "custom1": '{"value": "test1"}',
                "custom2": '{"value": "test2"}',
                "custom3": '{"value": "test3"}'
            }
            deployed_custom = {
                "custom2": '{"value": "test2"}'
            }
            result = find_deleted_custom_settings(backup_custom, deployed_custom)
            expected = {
                "custom1": '{"value": "test1"}',
                "custom3": '{"value": "test3"}'
            }
            self.assertEqual(result, expected)

        # Test with no deletions
        with self.subTest(scenario="no_deletions"):
            backup_custom = {
                "custom1": '{"value": "test1"}',
                "custom2": '{"value": "test2"}'
            }
            deployed_custom = {
                "custom1": '{"value": "test1"}',
                "custom2": '{"value": "test2"}'
            }
            result = find_deleted_custom_settings(backup_custom, deployed_custom)
            self.assertEqual(result, {})

    def test_restore_deleted_settings(self):
        """Test settings restoration scenarios"""
        # Test with deletions
        with self.subTest(scenario="with_deletions"):
            deployed_config = {
                "network_connections": '{"test": "value"}',
                "agent.connection": '{"test": "value"}'
            }
            deleted_settings = {
                "custom1": '{"value": "test1"}',
                "custom2": '{"value": "test2"}'
            }
            result = restore_deleted_settings(deployed_config, deleted_settings)
            expected = {
                "network_connections": '{"test": "value"}',
                "agent.connection": '{"test": "value"}',
                "custom1": '{"value": "test1"}',
                "custom2": '{"value": "test2"}'
            }
            self.assertEqual(result, expected)

        # Test with no deletions
        with self.subTest(scenario="no_deletions"):
            deployed_config = {
                "network_connections": '{"test": "value"}',
                "agent.connection": '{"test": "value"}'
            }
            deleted_settings = {}
            result = restore_deleted_settings(deployed_config, deleted_settings)
            self.assertEqual(result, deployed_config)

    def test_save_json_file(self):
        """Test JSON file saving scenarios"""
        # Test successful saving
        with self.subTest(scenario="success"):
            test_data = {"test": "value", "number": 123}
            with tempfile.NamedTemporaryFile('w', delete=False) as f:
                temp_path = f.name
            try:
                result = save_json_file(temp_path, test_data)
                self.assertTrue(result)
                # Verify the file was saved correctly
                with open(temp_path, 'r') as f:
                    loaded_data = json.load(f)
                self.assertEqual(loaded_data, test_data)
            finally:
                os.remove(temp_path)

        # Test saving failure
        with self.subTest(scenario="failure"):
            test_data = {"test": "value"}
            invalid_path = "/invalid/directory/file.json"
            result = save_json_file(invalid_path, test_data)
            self.assertFalse(result)

    def test_split_key_handling(self):
        """Test split key handling for 4096 character limit"""
        self.assertEqual(get_base_key_name("device_connectors##0000000001"), "device_connectors")
        self.assertEqual(get_base_key_name("custom_setting##0000000002"), "custom_setting")
        self.assertEqual(get_base_key_name("regular_key"), "regular_key")

    def test_split_key_filtering(self):
        """Test that split API keys are properly filtered out"""
        config = {
            "device_connectors##0000000001": "api_part1",
            "device_connectors##0000000002": "api_part2",
            "custom_setting": "custom_value",
            "long_custom_setting##0000000001": "custom_value_part1",
            "long_custom_setting##0000000002": "custom_value_part2"
        }
        api_keys = ["device_connectors"]

        result = extract_custom_settings(config, api_keys)
        expected = {"custom_setting": "custom_value", "long_custom_setting##0000000001": "custom_value_part1", "long_custom_setting##0000000002": "custom_value_part2"}
        self.assertEqual(result, expected)



if __name__ == "__main__":
    unittest.main()