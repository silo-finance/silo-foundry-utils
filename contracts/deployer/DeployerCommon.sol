// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {console2} from "forge-std/console2.sol";

import {AddressesCollection} from "../networks/addresses/AddressesCollection.sol";
import {IDeployerSharedMemory} from "./IDeployerSharedMemory.sol";
import {Utils} from "../lib/Utils.sol";
import {Deployments} from "../lib/Deployments.sol";
import {VmLib} from "../lib/VmLib.sol";

abstract contract DeployerCommon is AddressesCollection {
    /// @dev The struct that describes the deployment
    struct Deployment {
        string name; // The name of the smart contract with an extension: `Counter.vy`
        string deploymentsSubDir; // The directory for the ABI allocation `deploymentsSubDir/deployments/<network>`
        string bytecode; // The bytecode of the deployed smart contract
        string deployedByteCode; // The deployed bytecode of the deployed smart contract
        string contractABI; // An ABI of the deployed smart contract
        string compilerVersion; // The compiler version
        string forgeOutDir; // The forge `out` directory
        address addr; // The address of the deployed smart contract
        bool synced; // The flag shows whether the smart contract is already synced or not
    }

    // Note: IS_SCRIPT() must return true.
    bool public constant IS_SCRIPT = true;

    /// @dev The list of the deployments
    Deployment[] internal _deployments;

    /// @notice Disables deployments synchronization
    function disableDeploymentsSync() public {
        Deployments.disableDeploymentsSync();
    }

    /// @notice Enables deployments synchronization
    function enableDeploymentsSync() public {
        Deployments.enableDeploymentsSync();
    }

    /// @dev The developer can operate from scripts if it is needed to synchronize deployments.
    /// For example, deployments synchronization should be disabled in tests but enabled in scripts.
    function deploymentsSyncDisabled() public view returns (bool result) {
        result = Deployments.deploymentsSyncDisabled();
    }

    /// @notice Resolves an address by specified `_key` for the current chain id
    /// @param _key The key to resolving an address (Smart contract name with an extension: Counter.vy)
    function getDeployedAddress(string memory _key) public virtual returns (address shared) {
        console2.log("DeployerCommon.getDeployedAddress starting");

        shared = getAddress(_key);

        console2.log("DeployerCommon.getDeployedAddress shared: %s", shared);

        if (shared == address(0)) {
            string memory deploymentsDir = _deploymentsSubDir();
            string memory chainAlias = getChainAlias();

            shared = Deployments.getAddress(deploymentsDir, chainAlias, _key);
        }

        console2.log("DeployerCommon.getDeployedAddress shared: %s", shared);

        if (shared != address(0)) {
            VmLib.vm().label(shared, _key);
        }

        console2.log("DeployerCommon.getDeployedAddress complete");
    }

    /// @notice Register deployed smart contract
    function _registerDeployment(address _deployedAddress, string memory _fileName) internal {
        _registerDeployment(_deployedAddress, _deploymentsSubDir(), _fileName, _forgeOutDir());
    }

    /// @notice Register deployed smart contract
    function _registerDeployment(
        address _deployedAddress,
        string memory _subDir,
        string memory _fileName,
        string memory _outDir
    ) internal {
        /// @dev Revert on an attemp to register `solidity` deployment with specifying the Forge `out` dir
        if (bytes(_outDir).length == 0) revert("ForgeOutDirIsRequired");

        string memory empty;

        _deployments.push(
            Deployment({
                name: _fileName,
                deploymentsSubDir: _subDir,
                addr: _deployedAddress,
                bytecode: empty,
                deployedByteCode: empty,
                contractABI: empty,
                compilerVersion: empty,
                forgeOutDir: _outDir,
                synced: false
            })
        );

        _syncDeployments();
    }

    /// @notice Synchronize deployments by calling an external script
    function _syncDeployments() internal {
        uint256 totalDeployments = _deployments.length;

        for (uint256 i = 0; i < totalDeployments; i++) {
            Deployment storage deployment = _deployments[i];

            if (deployment.synced) continue;

            // allocate a deployed address into the shared memory
            setAddress(deployment.name, deployment.addr);

            deployment.synced = true;

            if (deploymentsSyncDisabled()) continue;

            if (bytes(deployment.contractABI).length != 0) {
                _syncVyperDeployments(deployment);
            } else if (bytes(deployment.forgeOutDir).length != 0) {
                _syncSolidityDeployments(deployment);
            } else {
                /// @dev Revert if registered an invalid deployment
                revert("InvalidDeployment");
            }
        }
    }

    function _syncSolidityDeployments(Deployment storage deployment) internal virtual {}

    function _syncVyperDeployments(Deployment storage deployment) internal virtual {}

    function _forgeOutDir() internal pure virtual returns (string memory) {}

    function _deploymentsSubDir() internal pure virtual returns (string memory) {}

    function _contractBaseDir() internal pure virtual returns (string memory) {}
}
