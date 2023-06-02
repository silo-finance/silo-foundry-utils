// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Counter {
    uint256 public someNumber;
    uint256 public multiplier;

    constructor(uint256 _mult) {
        multiplier = _mult;
    }

    function setSomeNumber(uint256 _val) external {
        someNumber = _val;
    }
    function increment() external {
        someNumber = someNumber + 1;
    }
}
