// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {EthereumAddresses} from "./EthereumAddresses.sol";
import {IAddressCollection} from "./IAddressCollection.sol";

contract AddressesCollection is EthereumAddresses {
    constructor() {
        initializeEthereumAddresses();
    }

    /// @notice Resolves an address by specified `_key` for the current chain id
    /// @param _key The key to resolving an address (Smart contract name with an extension: Counter.vy)
    function getDeployedAddress(string memory _key) public virtual returns (address shared) {
        shared = getAddress(_key);

        if (shared == address(0)) {
            // TODO: read from deployments
        }
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
