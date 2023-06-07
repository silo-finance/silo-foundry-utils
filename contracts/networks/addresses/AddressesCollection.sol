// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {EthereumAddresses} from "./EthereumAddresses.sol";
import {IAddressCollection} from "./IAddressCollection.sol";

contract AddressesCollection is EthereumAddresses {
    constructor() {
        initializeEthereumAddresses();
    }

    /// @notice Resolves an address by specified `_key` for the current chain id
    /// @param _key The key to resolving an address
    function getAddress(string memory _key) public view returns (address) {
        uint256 chainId = getChainId();

        return getAddress(chainId, _key);
    }

    /// @notice Resolves an address by specified `_key` and `_chainId`
    /// @param _chainId A chain identifier for which we want to resolve an address
    /// @param _key The key to resolving an address
    function getAddress(uint256 _chainId, string memory _key) public view returns (address) {
        return IAddressCollection(_ADDRESS_COLLECTION).getAddress(_chainId, _key);
    }
}