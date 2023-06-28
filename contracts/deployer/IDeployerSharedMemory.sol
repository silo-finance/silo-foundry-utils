// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDeployerSharedMemory {
    function deploymentsSyncDisabled() external view returns (bool);
}
