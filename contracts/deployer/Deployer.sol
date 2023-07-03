// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import {VyperDeployer} from "./Vyper.sol";
import {AddressesCollection} from "../networks/addresses/AddressesCollection.sol";
import {IDeployerSharedMemory} from "./IDeployerSharedMemory.sol";

contract Deployer is VyperDeployer, AddressesCollection {
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

    bool public constant DEPLOYMENTS_SYNC_DISABLED_FLAG = true;
    bool public constant DEPLOYMENTS_SYNC_ENABLED_FLAG = false;

    address public constant DEPLOYER_SHARED_MEMORY =
        address(uint160(uint256(keccak256("silo foundry utils: deployer"))));

    /// @dev The list of the deployments
    Deployment[] private _deployments;

    /// @dev Revert on an attemp to register `solidity` deployment with specifying the Forge `out` dir
    error ForgeOutDirIsRequired();

    /// @dev Revert if registered an invalid deployment
    error InvalidDeployment();

    /// @notice Disables deployments synchronization
    function disableDeploymentsSync() public {
        _mockDeploymentsSyncStatus(DEPLOYMENTS_SYNC_DISABLED_FLAG);
    }

    /// @notice Enables deployments synchronization
    function enableDeploymentsSync() public {
        _mockDeploymentsSyncStatus(DEPLOYMENTS_SYNC_ENABLED_FLAG);
    }

    /// @dev The developer can operate from scripts if it is needed to synchronize deployments.
    /// For example, deployments synchronization should be disabled in tests but enabled in scripts.
    function deploymentsSyncDisabled() public view returns (bool result) {
        (, bytes memory data) =
            DEPLOYER_SHARED_MEMORY.staticcall(abi.encodePacked(IDeployerSharedMemory.deploymentsSyncDisabled.selector));

        if (data.length == 0) return DEPLOYMENTS_SYNC_ENABLED_FLAG;

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(data, 0x20))
        }
    }

    /// @dev Allocate in the `shared memory` a flag that marks wether the deployments synchronization in enabled or not
    function _mockDeploymentsSyncStatus(bool _flag) internal {
        vm.mockCall(
            DEPLOYER_SHARED_MEMORY, abi.encodeCall(IDeployerSharedMemory.deploymentsSyncDisabled, ()), abi.encode(_flag)
        );
    }

    /// @notice Deploy smart contract
    /// @param _fileName The smart contract file name with an extension: `Counter.vy`
    /// @return deployedAddress An address of the deployed smart contract
    function _deploy(string memory _fileName, bytes memory _args) internal returns (address deployedAddress) {
        deployedAddress = _deploy(_contractBaseDir(), _deploymentsSubDir(), _fileName, _args);
    }

    /// @notice Deploy smart contract
    /// @param _folder The smart contract allocation folder
    /// @param _subDir The directory for the ABI allocation
    /// @param _fileName The smart contract file name with an extension: `Counter.vy`
    /// @return deployedAddress An address of the deployed smart contract
    function _deploy(string memory _folder, string memory _subDir, string memory _fileName, bytes memory _args)
        internal
        returns (address deployedAddress)
    {
        string memory path = string.concat(_folder, "/", _fileName);

        string memory bytecode;
        string memory deployedByteCode;
        string memory contractABI;
        string memory compilerVersion;

        (deployedAddress, bytecode, deployedByteCode, contractABI, compilerVersion) = _deployContract(path, _args);

        string memory empty;

        _deployments.push(
            Deployment({
                name: _fileName,
                deploymentsSubDir: _subDir,
                addr: deployedAddress,
                bytecode: bytecode,
                deployedByteCode: deployedByteCode,
                contractABI: contractABI,
                compilerVersion: compilerVersion,
                forgeOutDir: empty,
                synced: false
            })
        );

        return deployedAddress;
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
        if (bytes(_outDir).length == 0) revert ForgeOutDirIsRequired();

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
                revert InvalidDeployment();
            }
        }
    }

    function _forgeOutDir() internal pure virtual returns (string memory) {}

    function _deploymentsSubDir() internal pure virtual returns (string memory) {}

    function _contractBaseDir() internal pure virtual returns (string memory) {}

    function _syncSolidityDeployments(Deployment storage deployment) private {
        uint256 cmdLen = 10;

        if (bytes(deployment.deploymentsSubDir).length != 0) {
            cmdLen += 2;
        }

        string[] memory cmds = new string[](cmdLen);
        cmds[0] = "./silo-foundry-utils";
        cmds[1] = "sync";
        cmds[2] = "--network";
        cmds[3] = getChainIdAsString();
        cmds[4] = "--file";
        cmds[5] = deployment.name;
        cmds[6] = "--address";
        cmds[7] = vm.toString(deployment.addr);
        cmds[8] = "--out_dir";
        cmds[9] = deployment.forgeOutDir;

        if (bytes(deployment.deploymentsSubDir).length != 0) {
            cmds[10] = "--deployments_sub_dir";
            cmds[11] = deployment.deploymentsSubDir;
        }

        vm.ffi(cmds);
    }

    function _syncVyperDeployments(Deployment storage deployment) private {
        uint256 cmdLen = 16;

        if (bytes(deployment.deploymentsSubDir).length != 0) {
            cmdLen += 2;
        }

        string[] memory cmds = new string[](cmdLen);
        cmds[0] = "./silo-foundry-utils";
        cmds[1] = "sync";
        cmds[2] = "--network";
        cmds[3] = getChainIdAsString();
        cmds[4] = "--file";
        cmds[5] = deployment.name;
        cmds[6] = "--address";
        cmds[7] = vm.toString(deployment.addr);
        cmds[8] = "--bytecode";
        cmds[9] = deployment.bytecode;
        cmds[10] = "--d_bytecode";
        cmds[11] = deployment.deployedByteCode;
        cmds[12] = "--abi";
        cmds[13] = deployment.contractABI;
        cmds[14] = "--compiler";
        cmds[15] = deployment.compilerVersion;

        if (bytes(deployment.deploymentsSubDir).length != 0) {
            cmds[16] = "--deployments_sub_dir";
            cmds[17] = deployment.deploymentsSubDir;
        }

        // run command
        vm.ffi(cmds);
    }
}
