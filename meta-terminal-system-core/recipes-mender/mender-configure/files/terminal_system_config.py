#!/usr/bin/python3

import sys
import argparse
import requests
from requests.auth import HTTPBasicAuth
import json
import threading
import os.path
import subprocess
import logging
from enum import Enum, auto
from dataclasses import dataclass

# Parse args
parser = argparse.ArgumentParser()
parser.add_argument("config_path", type=str)
parser.add_argument("--update", action="store_true")
parser.add_argument("--no_send_inventory", action="store_true")
parser.add_argument("--addr", type=str, default="localhost")
parser.add_argument("--port", type=int, default=8081)
parser.add_argument("--api_version", type=str, default="api")
parser.add_argument("--log", type=str, default="INFO")
parser.add_argument("--user", type=str, default="")
parser.add_argument("--password", type=str, default="")
args = parser.parse_args()

# logging setting
logging.basicConfig(
    level=getattr(logging, args.log.upper()), format="%(levelname)s: %(message)s"
)


class ResultCode(Enum):
    SUCCESS = 0
    ERROR = 1
    # 20: mender-configure reboot return code
    SUCCESS_NEEDS_REBOOT = 20
    # 21: mender-configure treats it as an error, but the reboot process is performed at rollback
    ERROR_NEEDS_REBOOT = 21


class Result:
    def __init__(self, code: ResultCode, value=None):
        self.code = code
        self.value = value

    def ok(self):
        return self.code in (ResultCode.SUCCESS, ResultCode.SUCCESS_NEEDS_REBOOT)

    def err(self):
        return self.code in (ResultCode.ERROR, ResultCode.ERROR_NEEDS_REBOOT)

    def needs_reboot(self):
        return self.code in (
            ResultCode.SUCCESS_NEEDS_REBOOT,
            ResultCode.ERROR_NEEDS_REBOOT,
        )

    def set_ok(self):
        if self.needs_reboot():
            self.code = ResultCode.SUCCESS_NEEDS_REBOOT
        else:
            self.code = ResultCode.SUCCESS

    def set_err(self):
        if self.needs_reboot():
            self.code = ResultCode.ERROR_NEEDS_REBOOT
        else:
            self.code = ResultCode.ERROR

    def set_needs_reboot(self):
        if self.ok():
            self.code = ResultCode.SUCCESS_NEEDS_REBOOT
        else:
            self.code = ResultCode.ERROR_NEEDS_REBOOT


class ModifyMethod(Enum):
    PATCH = auto()
    PUT = auto()
    NONE = auto()


class ApiList:
    def __init__(self, base_uri):
        self.base_uri = base_uri
        self.list = {}

    def append(
        self,
        key,
        endpoint,
        modify_method=ModifyMethod.NONE,
        needs_reboot=False,
        needs_additional_post=False,
        additional_post_endpoint=None,
        support_get=True,
        support_query_force=False,
        hidden_config=False,
        modify_only=False,
        post_as_list=False,
    ):
        if key not in self.list:
            self.list[key] = {}
        self.list[key]["endpoint"] = f"{self.base_uri}{endpoint}"
        self.list[key]["modify_method"] = modify_method
        self.list[key]["needs_reboot"] = needs_reboot
        self.list[key]["needs_additional_post"] = needs_additional_post
        self.list[key][
            "additional_post_endpoint"
        ] = f"{self.base_uri}{additional_post_endpoint}"
        self.list[key]["support_get"] = support_get
        self.list[key]["support_query_force"] = support_query_force
        self.list[key]["hidden_config"] = hidden_config
        self.list[key]["modify_only"] = modify_only
        self.list[key]["post_as_list"] = post_as_list

    def keys(self):
        return self.list.keys()

    def endpoint(self, key):
        return self.list[key]["endpoint"]

    def modify_method(self, key):
        return self.list[key]["modify_method"]

    def needs_reboot(self, key):
        return self.list[key]["needs_reboot"]

    def needs_additional_post(self, key):
        return self.list[key]["needs_additional_post"]

    def additional_post_endpoint(self, key):
        return self.list[key]["additional_post_endpoint"]

    def support_get(self, key):
        return self.list[key]["support_get"]

    def support_query_force(self, key):
        return self.list[key]["support_query_force"]

    def hidden_config(self, key):
        return self.list[key]["hidden_config"]

    def modify_only(self, key):
        return self.list[key]["modify_only"]

    def post_as_list(self, key):
        return self.list[key]["post_as_list"]


@dataclass(frozen=True)
class RequestsItem:
    url: str
    data: dict = None
    needs_reboot: bool = False
    needs_additional_post: bool = False
    additional_post_endpoint: str = None


class TerminalSystemCoreUtils:
    def __init__(
        self, addr="localhost", port=8081, api_version="api", user="", password=""
    ):
        self.lock = threading.Lock()
        self.apply_result = None
        self.auth = HTTPBasicAuth(user, password) if user and password else None
        self.ids = ["id", "uuid"]
        self.deploy_options_key = "deploy_options"
        # mender-configure is managed with a single key/value pair
        self.api_list = ApiList(f"http://{addr}:{port}/{api_version}")
        self.api_list.append(
            "network_connections",
            "/network_connections",
            ModifyMethod.PATCH,
            needs_reboot=True,
        )
        self.api_list.append(
            "agent.connection", "/agent/connection", ModifyMethod.PATCH
        )
        self.api_list.append("agent.transport", "/agent/transport", ModifyMethod.PATCH)
        self.api_list.append("agent.upstreams", "/agent/upstreams", ModifyMethod.PATCH)
        self.api_list.append(
            "agent.downstreams", "/agent/downstreams", ModifyMethod.PATCH
        )
        self.api_list.append(
            "agent.filters_upstream", "/agent/filters_upstream", ModifyMethod.PATCH
        )
        self.api_list.append(
            "agent.filters_downstream", "/agent/filters_downstream", ModifyMethod.PATCH
        )
        self.api_list.append(
            "agent.deferred_upload", "/agent/deferred_upload", ModifyMethod.PATCH
        )
        self.api_list.append("agent.streamer", "/agent/streamer", ModifyMethod.PATCH)
        self.api_list.append(
            "agent.device_connectors_upstream",
            "/agent/device_connectors_upstream",
            ModifyMethod.PATCH,
        )
        self.api_list.append(
            "agent.device_connectors_downstream",
            "/agent/device_connectors_downstream",
            ModifyMethod.PATCH,
        )
        self.api_list.append(
            "device_connectors",
            "/device_connectors",
            ModifyMethod.PATCH,
            needs_additional_post=True,
            additional_post_endpoint="/device_connectors/-/commit",
            support_query_force=True,
        )
        self.api_list.append(
            "agent.measurements.suspend_deferred_upload",
            "/agent/measurements/suspend_deferred_upload",
            support_get=False,
            hidden_config=True,
            post_as_list=True,
        )
        self.api_list.append(
            "agent.measurements.unsuspend_deferred_upload",
            "/agent/measurements/unsuspend_deferred_upload",
            support_get=False,
            hidden_config=True,
            post_as_list=True,
        )
        self.api_list.append(
            "terminal_system.identification",
            "/terminal_system/identification",
            ModifyMethod.PATCH,
        )
        self.api_list.append(
            "time_sync",
            "/time_sync",
            ModifyMethod.PATCH,
            needs_reboot=True,
        )
        self.api_list.append(
            "gps",
            "/gps",
            ModifyMethod.PATCH,
            needs_reboot=True,
        )
        self.api_list.append(
            "ip_allowlist",
            "/ip_allowlist",
            ModifyMethod.PUT,
        )
        self.api_list.append(
            "diagnostic_monitors",
            "/diagnostic_monitors",
            ModifyMethod.PUT,
        )
        self.api_list.append("docker.composes", "/docker/composes", ModifyMethod.PATCH)

    def __get_id(self, d):
        for id in self.ids:
            if id in d:
                return d[id]
        return None

    def __get_deploy_options_force(self, configs_mender):
        deploy_options = configs_mender.get(self.deploy_options_key)
        if isinstance(deploy_options, str):
            try:
                deploy_options = json.loads(deploy_options)
            except json.JSONDecodeError:
                logging.error("Failed to decode deploy_options as JSON.")
                return False
        if not isinstance(deploy_options, dict):
            return False
        return deploy_options.get("force", False)

    def __query_params_deploy_options_force(self):
        return "?force=true"


    def __parse_lists(self, json_mender, json_current):
        added_list = []
        modify_list = []
        delete_list = []

        # parse added/modify
        for new in json_mender:
            found = False
            modify = False
            new_id = self.__get_id(new)

            if new_id:
                for cur in json_current:
                    cur_id = self.__get_id(cur)
                    if new_id == cur_id:
                        found = True
                        if new != cur:
                            modify = True

            if found:
                if modify:
                    modify_list.append(new)
            else:
                added_list.append(new)

        # parse delete
        for cur in json_current:
            found = False
            cur_id = self.__get_id(cur)

            for new in json_mender:
                new_id = self.__get_id(new)
                if new_id == cur_id:
                    found = True

            if not found:
                delete_list.append(cur)

        return (added_list, modify_list, delete_list)

    def __get_requests_list(self, configs_mender, configs_current):
        requests_list = {"post": [], "patch": [], "put": [], "delete": []}
        deploy_options_force = self.__get_deploy_options_force(configs_mender)

        for key in configs_mender.keys():
            if key not in self.api_list.keys():
                if key != self.deploy_options_key:
                    logging.info(
                        f'ignore "{key}" key, not included in Terminal System API.'
                    )
                continue

            try:
                json_mender = json.loads(configs_mender[key])
                if self.api_list.support_get(key):
                    json_current = json.loads(configs_current[key])
                else:
                    json_current = {}
            except json.decoder.JSONDecodeError:
                logging.error(f'invalid json value, ignore "{key}" value.')
                self.apply_result.set_err()
                continue

            needs_reboot = self.api_list.needs_reboot(key)
            needs_additional_post = self.api_list.needs_additional_post(key)
            additional_post_endpoint = self.api_list.additional_post_endpoint(key)
            support_query_force = self.api_list.support_query_force(key)
            query_params = ""

            if isinstance(json_mender, list):
                added_list, modify_list, delete_list = self.__parse_lists(
                    json_mender, json_current
                )

                if any(modify_list):
                    for item in modify_list:
                        if support_query_force and deploy_options_force:
                            query_params = self.__query_params_deploy_options_force()
                        url = f"{self.api_list.endpoint(key)}/{self.__get_id(item)}{query_params}"
                        additional_post_endpoint_with_query = f"{additional_post_endpoint}{query_params}"
                        data = item
                        requests_item = RequestsItem(
                            url,
                            data,
                            needs_reboot,
                            needs_additional_post,
                            additional_post_endpoint_with_query,
                        )

                        if ModifyMethod.PUT == self.api_list.modify_method(key):
                            requests_list["put"].append(requests_item)
                        elif ModifyMethod.PATCH == self.api_list.modify_method(key):
                            requests_list["patch"].append(requests_item)

                        else:
                            logging.error("invalid update method")
                            sys.exit(ResultCode.ERROR.value)

                if self.api_list.modify_only(key):
                    continue

                if any(added_list):
                    if support_query_force and deploy_options_force:
                        query_params = self.__query_params_deploy_options_force()
                    url = f"{self.api_list.endpoint(key)}{query_params}"
                    additional_post_endpoint_with_query = f"{additional_post_endpoint}{query_params}"

                    if self.api_list.post_as_list(key):
                        data = added_list
                        requests_item = RequestsItem(
                            url,
                            data,
                            needs_reboot,
                            needs_additional_post,
                            additional_post_endpoint_with_query,
                        )
                        requests_list["post"].append(requests_item)
                    else:
                        for item in added_list:
                            data = item
                            requests_item = RequestsItem(
                                url,
                                data,
                                needs_reboot,
                                needs_additional_post,
                                additional_post_endpoint_with_query,
                            )
                            requests_list["post"].append(requests_item)

                if any(delete_list):
                    for item in delete_list:
                        if support_query_force and deploy_options_force:
                            query_params = self.__query_params_deploy_options_force()
                        # NOTE: DELETE method does not support force query parameters
                        url = f"{self.api_list.endpoint(key)}/{self.__get_id(item)}"
                        additional_post_endpoint_with_query = f"{additional_post_endpoint}{query_params}"
                        requests_item = RequestsItem(
                            url,
                            None,
                            needs_reboot,
                            needs_additional_post,
                            additional_post_endpoint_with_query,
                        )
                        requests_list["delete"].append(requests_item)

            elif isinstance(json_mender, dict):
                if json_mender != json_current:
                    # NOTE: Currently, there is no endpoint for force deploy options in the case of a dictionary.
                    url = f"{self.api_list.endpoint(key)}{query_params}"
                    data = json_mender
                    requests_item = RequestsItem(
                        url,
                        data,
                        needs_reboot,
                        needs_additional_post,
                        additional_post_endpoint,
                    )

                    if ModifyMethod.PUT == self.api_list.modify_method(key):
                        requests_list["put"].append(requests_item)
                    elif ModifyMethod.PATCH == self.api_list.modify_method(key):
                        requests_list["patch"].append(requests_item)

            else:
                logging.error(f"invalid instance : {type(json_mender)} {json_mender}")
                sys.exit(ResultCode.ERROR.value)

        return requests_list

    def __call_requests_from_list(self, requests_list):
        additional_post_requests_list = []

        # requests
        # NOTE: Must call delete first to avoid resource conflicts
        for method in ["delete", "post", "put", "patch"]:
            for requests_item in requests_list[method]:
                res = requests.Response()

                if method == "delete":
                    res = requests.delete(requests_item.url, auth=self.auth)
                elif method == "post":
                    res = requests.post(
                        requests_item.url, json=requests_item.data, auth=self.auth
                    )
                elif method == "put":
                    res = requests.put(
                        requests_item.url, json=requests_item.data, auth=self.auth
                    )
                elif method == "patch":
                    res = requests.patch(
                        requests_item.url, json=requests_item.data, auth=self.auth
                    )

                if res.ok:
                    logging.info(f"requests success: {method} {requests_item.url}")

                    if requests_item.needs_reboot:
                        self.apply_result.set_needs_reboot()

                    if requests_item.needs_additional_post:
                        additional_post_requests_item = RequestsItem(
                            requests_item.additional_post_endpoint
                        )
                        additional_post_requests_list.append(
                            additional_post_requests_item
                        )

                else:
                    try:
                        res_json = res.json()
                    except requests.exceptions.JSONDecodeError:
                        logging.error(
                            f"requests error: {method} {requests_item.url}, Error while decoding JSON: {res}, text = {res.text}"
                        )
                    else:
                        logging.error(
                            f"requests error: {method} {requests_item.url}, res = {res_json}"
                        )
                    self.apply_result.set_err()

        # additional post requests
        # NOTE: Delete duplicate requests
        additional_post_requests_set = set(additional_post_requests_list)

        for requests_item in additional_post_requests_set:
            res = requests.post(
                requests_item.url, json=requests_item.data, auth=self.auth
            )
            if res.ok:
                logging.info(f"requests success: additional post {requests_item.url}")
            else:
                try:
                    res_json = res.json()
                except requests.exceptions.JSONDecodeError:
                    logging.error(
                        f"requests error: additional post {requests_item.url}, Error while decoding JSON: {res}, text = {res.text}"
                    )
                else:
                    logging.error(
                        f"requests error: additional post {requests_item.url}, res = {res_json}"
                    )
                self.apply_result.set_err()

    def apply_configs(self, configs_mender) -> Result:
        result = self.get_configs_current()
        if result.ok():
            (configs_current, _) = result.value
        else:
            return Result(ResultCode.ERROR)

        with self.lock:
            self.apply_result = Result(ResultCode.SUCCESS)
            requests_list = self.__get_requests_list(configs_mender, configs_current)
            self.__call_requests_from_list(requests_list)

        return self.apply_result

    def get_configs_current(self) -> Result:
        result_code = ResultCode.SUCCESS
        delete_keys = []
        delete_keys.append(self.deploy_options_key)
        with self.lock:
            configs_current = {}
            for key in self.api_list.keys():
                if self.api_list.hidden_config(key):
                    delete_keys.append(key)

                if not self.api_list.support_get(key):
                    continue

                res = requests.get(self.api_list.endpoint(key), auth=self.auth)
                if res.ok:
                    value = res.json()
                    configs_current[key] = json.dumps(value)
                else:
                    logging.error(f'failed to get config "{key}", res = {res}')
                    result_code = ResultCode.ERROR
            return Result(result_code, (configs_current, delete_keys))


class TerminalSystemConfig:
    def __init__(self, config_path):
        self.config_value_max_length = 4096
        self.config_key_split_delimiter = "##"
        self.config_path = config_path
        self.configs_mender = self.__load_config_file(self.config_path)
        self.ts_core_utils = TerminalSystemCoreUtils(
            addr=args.addr,
            port=args.port,
            api_version=args.api_version,
            user=args.user,
            password=args.password,
        )

    def __merge_values(self, config_json):
        merged_config = {}
        keys_to_remove = []

        sorted_keys = sorted(config_json.keys())

        for key in sorted_keys:
            if self.config_key_split_delimiter in key:
                base_key, suffix = key.rsplit(self.config_key_split_delimiter, 1)
                if suffix.isdigit():
                    if base_key not in merged_config:
                        merged_config[base_key] = ""
                    merged_config[base_key] += config_json[key]
                    keys_to_remove.append(key)
            else:
                if key not in merged_config:
                    merged_config[key] = config_json[key]

        for key in keys_to_remove:
            del config_json[key]

        for key, value in merged_config.items():
            config_json[key] = value

        return config_json

    def __load_config_file(self, config_path):
        config_json = {}
        with open(config_path, "r") as f:
            try:
                config_json = json.load(f)
                if config_json is None:
                    config_json = {}
                else:
                    config_json = self.__merge_values(config_json)
            except json.decoder.JSONDecodeError:
                logging.warning("invalid config file, empty contents.")
                pass
        return config_json

    def __split_value(self, key, value, max_length):
        if not isinstance(value, str):
            raise TypeError(f"Value for key '{key}' must be a string.")

        if len(value) <= max_length:
            return {key: value}

        parts = [value[i : i + max_length] for i in range(0, len(value), max_length)]
        split_dict = {f"{key}{self.config_key_split_delimiter}{i+1:010d}": part for i, part in enumerate(parts)}
        return split_dict

    def __split_values(self, config_json):
        split_config = {}
        for key, value in config_json.items():
            if isinstance(value, str) and len(value) > self.config_value_max_length:
                split_parts = self.__split_value(key, value, self.config_value_max_length)
                split_config.update(split_parts)
            else:
                split_config[key] = value
        return split_config

    def __write_config_file(self, config_path, config_json):
        config_json = self.__split_values(config_json)
        with open(config_path, "w") as f:
            json.dump(config_json, f, sort_keys=True, indent=2)

    def apply(self) -> Result:
        configs_mender = self.configs_mender

        if not any(configs_mender):
            # no need to update
            return Result(ResultCode.SUCCESS)

        return self.ts_core_utils.apply_configs(configs_mender)

    def update(self) -> Result:
        # Keep other keys
        configs_mender = self.configs_mender

        result = self.ts_core_utils.get_configs_current()
        if result.ok():
            (configs_current, delete_keys) = result.value
        else:
            return Result(ResultCode.ERROR)

        for key in configs_current:
            configs_mender[key] = configs_current[key]

        for key in delete_keys:
            if key in configs_mender:
                del configs_mender[key]

        self.__write_config_file(self.config_path, configs_mender)

        return Result(ResultCode.SUCCESS)


def main():
    config_path = args.config_path
    if not os.path.exists(config_path):
        logging.error(f"{config_path} does not exist.")
        sys.exit(ResultCode.ERROR.value)

    ts_config = TerminalSystemConfig(config_path)

    if args.update:
        result = ts_config.update()
    else:
        result_apply = ts_config.apply()

        # reload default value and revert invalid value
        result_update = ts_config.update()

        # synchronize configs immediately
        if not args.no_send_inventory:
            subprocess.run(["mender", "send-inventory"])

        # merge results
        if result_apply.ok() and result_update.ok():
            if result_apply.needs_reboot():
                result = Result(ResultCode.SUCCESS_NEEDS_REBOOT)
            else:
                result = Result(ResultCode.SUCCESS)
        else:
            if result_apply.needs_reboot():
                result = Result(ResultCode.ERROR_NEEDS_REBOOT)
            else:
                result = Result(ResultCode.ERROR)

    if result.needs_reboot():
        logging.info(f"Reboot required")
    logging.debug(f"Exit Code: {result.code}")

    return result.code.value


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
        sys.exit(ResultCode.ERROR.value)
