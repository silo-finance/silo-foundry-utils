// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import {console2} from "forge-std/console2.sol";

import {VmLib} from "../lib/VmLib.sol";
import {Utils} from "../lib/Utils.sol";
import {Deployments} from "../lib/Deployments.sol";
import {AddrLib} from "../lib/AddrLib.sol";

library KeyValueStorage {
    bytes32 internal constant _EMPTY_RESULT = keccak256(abi.encodePacked(""));
    bytes32 internal constant _RESULT_TRUE = keccak256(abi.encodePacked("true"));
    bytes32 internal constant _PLACEHOLDER_KEY = keccak256(abi.encodePacked("PLACEHOLDER"));

    function setAddress(string memory _file, string memory _key1, string memory _key2, address _value) internal {
        AddrLib.setAddress(_key2, _value);

        set(_file, _key1, _key2, VmLib.vm().toString(_value));
    }

    function getAddress(string memory _file, string memory _key1, string memory _key2)
        internal
        returns (address result)
    {
        if (_key2 == _PLACEHOLDER_KEY) {
            return address(0);
        }

        console2.log("KeyValueStorage.getAddress starting");

        bytes memory data = get(_file, _key1, _key2);

        console2.log("data.length %s", data.length);
        console2.log("data is empty %s", keccak256(data) == _EMPTY_RESULT);

        if (keccak256(data) == _EMPTY_RESULT) {
            return address(0);
        }

        result = Utils.asciiBytesToAddress(data);

        console2.log("KeyValueStorage.getAddress result: %s", result);

        if (result != address(0)) {
            VmLib.vm().label(result, _key2);
        }
    }

    function getString(string memory _file, string memory _key1, string memory _key2)
        internal
        returns (string memory)
    {
        bytes memory data = get(_file, _key1, _key2);
        if (keccak256(data) == _EMPTY_RESULT) {
            return "";
        }

        return string(removeBr(data));
    }

    function getBoolean(string memory _file, string memory _key1, string memory _key2) internal returns (bool) {
        bytes memory data = get(_file, _key1, _key2);

        if (keccak256(data) == _RESULT_TRUE) {
            return true;
        }

        return false;
    }

    function getUint(string memory _file, string memory _key1, string memory _key2) internal returns (uint256) {
        bytes memory data = get(_file, _key1, _key2);
        if (keccak256(data) == _EMPTY_RESULT) {
            return 0;
        }

        return Utils.stringToUint(string(get(_file, _key1, _key2)));
    }

    function get(string memory _file, string memory _key1, string memory _key2)
        internal
        returns (bytes memory result)
    {
        console2.log("KeyValueStorage.get _file: %s", _file);
        console2.log("KeyValueStorage.get _key1: %s", _key1);
        console2.log("KeyValueStorage.get _key2: %s", _key2);

        uint256 cmdLen = bytes(_key1).length != 0 ? 8 : 6;

        string[] memory cmds = new string[](cmdLen);

        cmds[0] = "./silo-foundry-utils";
        cmds[1] = "key-val-json-read";
        cmds[2] = "--file";
        cmds[3] = _file;
        cmds[4] = "--key2";
        cmds[5] = _key2;

        if (bytes(_key1).length != 0) {
            cmds[6] = "--key1";
            cmds[7] = _key1;
        }

        console2.log("KeyValueStorage.get ffi");

        result = VmLib.vm().ffi(cmds);

        console2.log("KeyValueStorage.get complete");
    }

    function set(string memory _file, string memory _key1, string memory _key2, string memory _value) internal {
        if (Deployments.deploymentsSyncDisabled()) return;

        uint256 cmdLen = bytes(_key1).length != 0 ? 10 : 8;

        string[] memory cmds = new string[](cmdLen);
        cmds[0] = "./silo-foundry-utils";
        cmds[1] = "key-val-json";
        cmds[2] = "--file";
        cmds[3] = _file;
        cmds[4] = "--key2";
        cmds[5] = _key2;
        cmds[6] = "--value";
        cmds[7] = _value;

        if (bytes(_key1).length != 0) {
            cmds[8] = "--key1";
            cmds[9] = _key1;
        }

        VmLib.vm().ffi(cmds);
    }

    function removeBr(bytes memory _data) internal pure returns (bytes memory) {
        if (_data.length < 3) return _data;

        uint256 length = _data.length - 2;
        uint256 j = 0;

        bytes memory result = new bytes(length);

        for (uint256 i = 1; i <= length; i++) {
            result[j] = _data[i];
            j++;
        }

        return result;
    }
}
