// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CommonBase} from "forge-std/Base.sol";

import {Chains} from "../Chains.sol";
import {IAddressCollection} from "./IAddressCollection.sol";

abstract contract AddressesCollectionStorage is CommonBase, Chains {
    address constant internal _ADDRESS_COLLECTION =
        address(uint160(uint256(keccak256("silo foundry utils: address collection"))));

    string constant public SILO_TOKEN = "SILO";
    string constant public SILO80_WETH20_TOKEN = "80Silo-20WETH";

    /// @notice Allocates an address for the current chain id
    /// @param _key The key to allocating/resolving an address
    /// @param _value An address that should be allocated
    function setAddress(string memory _key, address _value) public {
        setAddress(getChainId(), _key, _value);
    }

    /// @notice Allocates an address
    /// @param _chainId A chain identifier that a `_value` is related to 
    /// @param _key The key to allocating/resolving an address
    /// @param _value An address that should be allocated
    function setAddress(uint256 _chainId, string memory _key, address _value) public {
        vm.mockCall(
            _ADDRESS_COLLECTION,
            abi.encodeCall(IAddressCollection.getAddress, (_chainId, _key)),
            abi.encode(_value)
        );
    }
}
