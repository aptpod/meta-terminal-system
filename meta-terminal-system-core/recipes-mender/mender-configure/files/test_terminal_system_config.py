import json
import unittest
import tempfile
import os
from unittest.mock import patch, MagicMock
from terminal_system_config import TerminalSystemConfig
from terminal_system_config import RequestsItem
from terminal_system_config import list_keys

class TestTerminalSystemConfig(unittest.TestCase):

    def setUp(self):
        pass

    def tearDown(self):
        if hasattr(self, 'config_path') and os.path.exists(self.config_path):
            os.remove(self.config_path)

    def init(self, config):
        with tempfile.NamedTemporaryFile('w', delete=False) as temp_file:
            json.dump(config, temp_file)
            self.config_path = temp_file.name
        self.config = TerminalSystemConfig(self.config_path)

    def config_dict_to_json(self, config_dict):
        for key in config_dict.keys():
            config_dict[key] = json.dumps(config_dict[key])
        return config_dict


    def test_merge_split_keys(self):
        self.init({})

        input = {
            "key_1": "0",
            "key_4096": "A" * 4096,
            "key_4097##0000000001": "A" * 4096,
            "key_4097##0000000002": "@",
            "key_8193##0000000001": "A" * 4096,
            "key_8193##0000000002": "A" * 4096,
            "key_8193##0000000003": "@",
            "key_skip_num##0000000100": " test.",
            "key_skip_num##0000000010": " is",
            "key_skip_num##0000000001": "This",
            "key_no_split##notanumber": "unchanged",
        }
        expected = {
            "key_1": "0",
            "key_4096": "A" * 4096,
            "key_4097": "A" * 4096 + "@",
            "key_8193": "A" * 4096 + "A" * 4096 + "@",
            "key_skip_num": "This is test.",
            "key_no_split##notanumber": "unchanged",
        }

        merged_result = self.config._TerminalSystemConfig__merge_split_keys(input)
        self.assertEqual(merged_result, expected)

    def test_split_long_values(self):
        self.init({})

        input = {
            "key_1": "0",
            "key_4096": "A" * 4096,
            "key_4097": "A" * 4096 + "@",
            "key_8193": "A" * 4096 + "A" * 4096 + "@",
        }
        expected = {
            "key_1": "0",
            "key_4096": "A" * 4096,
            "key_4097##0000000001": "A" * 4096,
            "key_4097##0000000002": "@",
            "key_8193##0000000001": "A" * 4096,
            "key_8193##0000000002": "A" * 4096,
            "key_8193##0000000003": "@",
        }

        split_result = self.config._TerminalSystemConfig__split_long_values(input)
        self.assertEqual(split_result, expected)

    def test_get_deploy_options_force(self):
        self.init({"deploy_options": {"force": True}})
        force = self.config.ts_core_utils._TerminalSystemCoreUtils__get_deploy_options_force(self.config.configs_mender)
        self.assertEqual(force, True)

        self.init({"deploy_options": {"force": False}})
        force = self.config.ts_core_utils._TerminalSystemCoreUtils__get_deploy_options_force(self.config.configs_mender)
        self.assertEqual(force, False)
        self.init({"deploy_options": {}})
        force = self.config.ts_core_utils._TerminalSystemCoreUtils__get_deploy_options_force(self.config.configs_mender)
        self.assertEqual(force, False)
        self.init({})
        force = self.config.ts_core_utils._TerminalSystemCoreUtils__get_deploy_options_force(self.config.configs_mender)
        self.assertEqual(force, False)

    def __get_requests_list(self, configs_current, configs_mender, force, expected):
        self.init({})

        configs_current = self.config_dict_to_json(configs_current)
        if force:
            configs_mender["deploy_options"] = {"force": True}
        configs_mender = self.config_dict_to_json(configs_mender)

        requests_list = self.config.ts_core_utils._TerminalSystemCoreUtils__get_requests_list(configs_mender, configs_current)
        self.assertEqual(requests_list, expected)

    def test_get_requests_list_modify(self):
        configs_current = {
            "device_connectors": [
                {
                    "id": "device-inventory",
                    "enabled": True,
                    "upstream_ipc_ids": ["device-inventory"],
                    "downstream_ipc_ids": [],
                    "service_id": "Device Inventory",
                    "service_substitutions": [],
                }
            ]
        }
        configs_mender = {
            "device_connectors": [
                {
                    "id": "device-inventory",
                    "enabled": True,
                    "upstream_ipc_ids": ["device-inventory"],
                    "downstream_ipc_ids": [],
                    "service_id": "Device Inventory",
                    "service_substitutions": ["DC_SEND_INTERVAL=20"],
                }
            ]
        }
        expected_force_false = {
            "post": [],
            "patch": [
                RequestsItem(
                    url="http://localhost:8081/api/device_connectors/device-inventory",
                    data={
                        "id": "device-inventory",
                        "enabled": True,
                        "upstream_ipc_ids": ["device-inventory"],
                        "downstream_ipc_ids": [],
                        "service_id": "Device Inventory",
                        "service_substitutions": ["DC_SEND_INTERVAL=20"],
                    },
                    needs_reboot=False,
                    needs_additional_post=True,
                    additional_post_endpoint="http://localhost:8081/api/device_connectors/-/commit",
                )
            ],
            "put": [],
            "delete": [],
        }
        expected_force_true = {
            "post": [],
            "patch": [
                RequestsItem(
                    url="http://localhost:8081/api/device_connectors/device-inventory?force=true",
                    data={
                        "id": "device-inventory",
                        "enabled": True,
                        "upstream_ipc_ids": ["device-inventory"],
                        "downstream_ipc_ids": [],
                        "service_id": "Device Inventory",
                        "service_substitutions": ["DC_SEND_INTERVAL=20"],
                    },
                    needs_reboot=False,
                    needs_additional_post=True,
                    additional_post_endpoint="http://localhost:8081/api/device_connectors/-/commit?force=true",
                )
            ],
            "put": [],
            "delete": [],
        }

        self.__get_requests_list(configs_current.copy(), configs_mender.copy(), False, expected_force_false)
        self.__get_requests_list(configs_current.copy(), configs_mender.copy(), True, expected_force_true)

    def test_get_requests_list_add(self):
        configs_current = {
            "device_connectors": []
        }
        configs_mender = {
            "device_connectors": [
                {
                    "id": "device-inventory",
                    "enabled": True,
                    "upstream_ipc_ids": ["device-inventory"],
                    "downstream_ipc_ids": [],
                    "service_id": "Device Inventory",
                    "service_substitutions": [],
                }
            ]
        }
        expected_force_false = {
            "post": [
                RequestsItem(
                    url="http://localhost:8081/api/device_connectors",
                    data={
                        "id": "device-inventory",
                        "enabled": True,
                        "upstream_ipc_ids": ["device-inventory"],
                        "downstream_ipc_ids": [],
                        "service_id": "Device Inventory",
                        "service_substitutions": [],
                    },
                    needs_reboot=False,
                    needs_additional_post=True,
                    additional_post_endpoint="http://localhost:8081/api/device_connectors/-/commit",
                )
            ],
            "patch": [],
            "put": [],
            "delete": [],
        }
        expected_force_true = {
            "post": [
                RequestsItem(
                    url="http://localhost:8081/api/device_connectors?force=true",
                    data={
                        "id": "device-inventory",
                        "enabled": True,
                        "upstream_ipc_ids": ["device-inventory"],
                        "downstream_ipc_ids": [],
                        "service_id": "Device Inventory",
                        "service_substitutions": [],
                    },
                    needs_reboot=False,
                    needs_additional_post=True,
                    additional_post_endpoint="http://localhost:8081/api/device_connectors/-/commit?force=true",
                )
            ],
            "patch": [],
            "put": [],
            "delete": [],
        }

        self.__get_requests_list(configs_current.copy(), configs_mender.copy(), False, expected_force_false)
        self.__get_requests_list(configs_current.copy(), configs_mender.copy(), True, expected_force_true)

    def test_get_requests_list_delete(self):
        configs_current = {
            "device_connectors": [
                {
                    "id": "device-inventory",
                    "enabled": True,
                    "upstream_ipc_ids": ["device-inventory"],
                    "downstream_ipc_ids": [],
                    "service_id": "Device Inventory",
                    "service_substitutions": [],
                }
            ]
        }
        configs_mender = {
            "device_connectors": []
        }
        expected_force_false = {
            "post": [],
            "patch": [],
            "put": [],
            "delete": [
                RequestsItem(
                    url="http://localhost:8081/api/device_connectors/device-inventory",
                    data=None,
                    needs_reboot=False,
                    needs_additional_post=True,
                    additional_post_endpoint="http://localhost:8081/api/device_connectors/-/commit",
                )
            ],
        }
        expected_force_true = {
            "post": [],
            "patch": [],
            "put": [],
            "delete": [
                RequestsItem(
                    url="http://localhost:8081/api/device_connectors/device-inventory",
                    data=None,
                    needs_reboot=False,
                    needs_additional_post=True,
                    additional_post_endpoint="http://localhost:8081/api/device_connectors/-/commit?force=true",
                )
            ],
        }

        self.__get_requests_list(configs_current.copy(), configs_mender.copy(), False, expected_force_false)
        self.__get_requests_list(configs_current.copy(), configs_mender.copy(), True, expected_force_true)

    def test_get_requests_list_put_dict(self):
        configs_current = {
            "network.connectivity_check": {"uri": ""}
        }
        configs_mender = {
            "network.connectivity_check": {"uri": "https://example.com/check"}
        }
        expected = {
            "post": [],
            "patch": [],
            "put": [
                RequestsItem(
                    url="http://localhost:8081/api/network/connectivity_check",
                    data={"uri": "https://example.com/check"},
                    needs_reboot=False,
                    needs_additional_post=False,
                    additional_post_endpoint="http://localhost:8081/apiNone",
                )
            ],
            "delete": [],
        }

        self.__get_requests_list(configs_current.copy(), configs_mender.copy(), False, expected)

    @patch('terminal_system_config.print')
    @patch('terminal_system_config.args')
    def test_list_keys(self, mock_args, mock_print):
        mock_args.addr = "localhost"
        mock_args.port = 8081
        mock_args.api_version = "api"
        mock_args.user = ""
        mock_args.password = ""

        normal_keys = [
            "network_connections",
            "agent.connection",
            "agent.transport",
            "agent.upstreams",
            "agent.downstreams",
            "agent.filters_upstream",
            "agent.filters_downstream",
            "agent.deferred_upload",
            "agent.streamer",
            "agent.device_connectors_upstream",
            "agent.device_connectors_downstream",
            "device_connectors",
            "terminal_system.identification",
            "time_sync",
            "gps",
            "ip_allowlist",
            "diagnostic_monitors",
            "network.connectivity_check",
            "docker.composes"
        ]

        hidden_keys = [
            "agent.measurements.suspend_deferred_upload",
            "agent.measurements.unsuspend_deferred_upload"
        ]

        ts_config = TerminalSystemConfig()

        with self.subTest(include_hidden=False):
            mock_args.include_hidden = False
            mock_print.reset_mock()

            list_keys(ts_config)

            printed_output = mock_print.call_args[0][0]
            keys_list = json.loads(printed_output)

            # Check that the output is a JSON list
            self.assertIsInstance(keys_list, list)

            # Check that all normal keys are included
            expected_keys_without_hidden = normal_keys
            self.assertEqual(set(keys_list), set(expected_keys_without_hidden))

            # Check that hidden config items are not included
            for hidden_key in hidden_keys:
                self.assertNotIn(hidden_key, keys_list)

        with self.subTest(include_hidden=True):
            mock_args.include_hidden = True
            mock_print.reset_mock()

            list_keys(ts_config)

            printed_output = mock_print.call_args[0][0]
            keys_list = json.loads(printed_output)

            # Check that the output is a JSON list
            self.assertIsInstance(keys_list, list)

            # Check that all keys (normal + hidden) are included
            expected_keys_with_hidden = normal_keys + hidden_keys
            self.assertEqual(set(keys_list), set(expected_keys_with_hidden))

            # Check that hidden config items are included
            for hidden_key in hidden_keys:
                self.assertIn(hidden_key, keys_list)


if __name__ == "__main__":
    unittest.main()
