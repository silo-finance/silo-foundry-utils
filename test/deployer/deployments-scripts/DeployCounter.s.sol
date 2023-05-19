// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../contracts/deployer/Deployer.sol";

// forge script test/deployer/deployments-scripts/DeployCounter.s.sol --ffi --broadcast --rpc-url http://127.0.0.1:8545
contract VyperCounterDeploy is Deployer {
     uint256 public testMultiplier = 100;

    string constant BASE_DIR = "test/deployer/mocks";
    string constant FILE = "Counter.vy";

    function setUp() public {}

    function run() public returns (address counter) {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(bytes32(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80))
        );

        vm.startBroadcast(deployerPrivateKey);

        counter = _deploy(BASE_DIR, FILE, abi.encodePacked(testMultiplier));

        vm.stopBroadcast();

        _syncDeployments();
    }
}
