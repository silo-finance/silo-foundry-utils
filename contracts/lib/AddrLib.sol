// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import {IAddressCollection} from "../networks/addresses/IAddressCollection.sol";
import {AddressesCollectionImpl} from "../networks/addresses/AddressesCollectionImpl.sol";
import {AddressesCollectionImplWrapper} from "../networks/addresses/AddressesCollectionImplWrapper.sol";
import {Utils} from "./Utils.sol";
import {VmLib} from "./VmLib.sol";

library AddrLib {
    address internal constant _ADDRESS_COLLECTION =
        address(uint160(uint256(keccak256("silo foundry utils: address collection"))));

    /// @notice Allocates an address for the current chain id
    /// @param _key The key to allocating/resolving an address
    /// @param _value An address that should be allocated
    function setAddress(string memory _key, address _value) internal {
        setAddress(getChainId(), _key, _value);
    }

    /// @notice Allocates an address
    /// @param _chainId A chain identifier that a `_value` is related to
    /// @param _key The key to allocating/resolving an address
    /// @param _value An address that should be allocated
    function setAddress(uint256 _chainId, string memory _key, address _value) internal {
        VmLib.vm().mockCall(
            _ADDRESS_COLLECTION,
            Utils.encodeGetAddressCall(IAddressCollection.getAddress.selector, _chainId, _key),
            abi.encode(_value)
        );

        VmLib.vm().label(_value, _key);
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

    /// @notice Resolves a chain identifier
    /// @return id The chain identifier
    function getChainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        } // solhint-disable-line no-inline-assembly
    }

    function init() internal {
        AddressesCollectionImpl collection = new AddressesCollectionImpl(3331, "test", address(1123));
        AddressesCollectionImplWrapper wrapper = new AddressesCollectionImplWrapper();

        bytes memory code = Utils.getCodeAt(address(wrapper));

        VmLib.vm().etch(_ADDRESS_COLLECTION, code);

        AddressesCollectionImplWrapper(_ADDRESS_COLLECTION).setCollection(address(collection));
    }
}
