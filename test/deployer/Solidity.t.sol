// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { CommonDeploymentTest } from "./_common.sol";

import "./mocks/ICounter.sol";
import "./deployments-scripts/SolidityCounterDeploy.s.sol";

// ./bash/build-for-tests.sh
// forge clean && forge test --match-contract DeploySolidityTest --ffi -vvv && ./bash/kill-anvil.sh
contract DeploySolidityTest is CommonDeploymentTest {
    string internal constant FILE = "Counter.sol";
    string internal constant DEPLOYMENT_SCRIPT = "test/deployer/deployments-scripts/SolidityCounterDeploy.s.sol";
    uint256 internal constant MULTIPLIER = 111;

    function test_deployment_script_in_tests() public {
        SolidityCounterDeploy script = new SolidityCounterDeploy();
        script.disableDeploymentsSync();

        address counterAddr = script.run();

        ICounter counter = ICounter(counterAddr);

        assertEq(
            counter.someNumber(),
            0,
            "Invalid number"
        );

        counter.increment();
        counter.increment();

        assertEq(
            counter.someNumber(),
            2,
            "Failed to increment"
        );
    }

    function getFileName() internal pure override returns (string memory) {
        return FILE;
    }

    function getDeploymentScript() internal pure override returns (string memory) {
        return DEPLOYMENT_SCRIPT;
    }

    function getMultiplier() internal pure override returns (uint256) {
        return MULTIPLIER;
    }
}
