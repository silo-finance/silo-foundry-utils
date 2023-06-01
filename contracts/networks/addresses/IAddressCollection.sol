// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAddressCollection {
    function getAddress(uint256 _chainId, string memory _key) external view returns (address);
}
