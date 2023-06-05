// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "silo-foundry-utils/deployer/Deployer.sol";

contract CommonDeploy is Deployer {
    // Common variables
    string internal constant FORGE_OUT_DIR = "out";
    string internal constant DEPLOYMENTS_SUB_DIR = "";
    string internal constant BASE_DIR = "test/deployer/mocks";

    // Smart contracts list
    string internal constant COUNTER_SOL = "Counter.sol";
    string internal constant COUNTER_VY = "Counter.vy";

    function _forgeOutDir() internal pure override virtual returns (string memory) {
        return FORGE_OUT_DIR;
    }

    function _deploymentsSubDir() internal pure override virtual returns (string memory) {
        return DEPLOYMENTS_SUB_DIR;
    }

    function _contractBaseDir() internal pure override virtual returns (string memory) {
        return BASE_DIR;
    }
}
