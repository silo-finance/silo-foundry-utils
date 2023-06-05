// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "silo-foundry-utils/networks/IntegrationTest.sol";

import "./mocks/A.sol";
import "./mocks/B.sol";

// forge test --match-contract AddressesCollectionTest -vvv
contract AddressesCollectionTest is IntegrationTest {
    A internal a = new A();
    B internal b = new B();

    address internal addr1 = address(1);
    address internal addr2 = address(2);

    string internal key1 = "key1";
    string internal key2 = "key2";
    
    function test_set_get_address() public {
        a.setAddress(key1, addr1);
        b.setAddress(key2, addr2);

        address resultKey2 = a.getAddress(key2);
        address resultKey1 = b.getAddress(key1);

        assertEq(addr1, resultKey1);
        assertEq(addr2, resultKey2);
    }
}
