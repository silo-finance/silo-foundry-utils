// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VyperDeployer} from "./Vyper.sol";

contract Deployer is VyperDeployer {
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

    /// @dev The developer can operate from scripts if it is needed to synchronize deployments.
    /// For example, deployments synchronization should be disabled in tests but enabled in scripts.
    bool public deploymentsSyncDisabled;

    /// @dev The list of the deployments
    Deployment[] private _deployments;

    /// @dev Revert on an attemp to register `solidity` deployment with specifying the Forge `out` dir
    error ForgeOutDirIsRequired();

    /// @dev Revert if registered an invalid deployment
    error InvalidDeployment();

    /// @notice Disables deployments synchronization
    function disableDeploymentsSync() external {
        deploymentsSyncDisabled = true;
    }

    /// @notice Enables deployments synchronization
    function enableDeploymentsSync() external {
        deploymentsSyncDisabled = false;
    }

    /// @notice Resolves a chain identifier
    /// @return chainIdAsString The chain identifier
    function getChainIdAsString() public view returns (string memory chainIdAsString) {
        uint256 currentChainID;
        assembly { currentChainID := chainid() } // solhint-disable-line no-inline-assembly
        chainIdAsString = vm.toString(currentChainID);
    }

    /// @notice Deploy smart contract
    /// @param _fileName The smart contract file name with an extension: `Counter.vy`
    /// @return deployedAddress An address of the deployed smart contract
    function _deploy(
        string memory _fileName,
        bytes memory _args
    )
        internal
        returns (address deployedAddress)
    {
        deployedAddress =  _deploy(
            _contractBaseDir(),
            _deploymentsSubDir(),
            _fileName,
            _args
        );
    }

    /// @notice Deploy smart contract
    /// @param _folder The smart contract allocation folder
    /// @param _subDir The directory for the ABI allocation
    /// @param _fileName The smart contract file name with an extension: `Counter.vy`
    /// @return deployedAddress An address of the deployed smart contract
    function _deploy(
        string memory _folder,
        string memory _subDir,
        string memory _fileName,
        bytes memory _args
    )
        internal
        returns (address deployedAddress)
    {
        string memory path = string.concat(_folder, "/", _fileName);

        string memory bytecode;
        string memory deployedByteCode;
        string memory contractABI;
        string memory compilerVersion;
        
        (
            deployedAddress,
            bytecode,
            deployedByteCode,
            contractABI,
            compilerVersion
        ) = _deployContract(path, _args);

        string memory empty;

        _deployments.push(Deployment({
            name: _fileName,
            deploymentsSubDir: _subDir,
            addr: deployedAddress,
            bytecode: bytecode,
            deployedByteCode: deployedByteCode,
            contractABI: contractABI,
            compilerVersion: compilerVersion,
            forgeOutDir: empty,
            synced: false
        }));

        return deployedAddress;
    }

    /// @notice Register deployed smart contract
    function _registerDeployment(
        address _deployedAddress,
        string memory _fileName
    )
        internal
    {
        _registerDeployment(
            _deployedAddress,
            _deploymentsSubDir(),
            _fileName,
            _forgeOutDir()
        );
    }

    /// @notice Register deployed smart contract
    function _registerDeployment(
        address _deployedAddress,
        string memory _subDir,
        string memory _fileName,
        string memory _outDir
    )
        internal
    {
        if (bytes(_outDir).length == 0) revert ForgeOutDirIsRequired();

        string memory empty;

        _deployments.push(Deployment({
            name: _fileName,
            deploymentsSubDir: _subDir,
            addr: _deployedAddress,
            bytecode: empty,
            deployedByteCode: empty,
            contractABI: empty,
            compilerVersion: empty,
            forgeOutDir: _outDir,
            synced: false
        }));
    }

    /// @notice Synchronize deployments by calling an external script
    function _syncDeployments() internal {
        if (deploymentsSyncDisabled) return;

        uint256 totalDeployments = _deployments.length;

        for (uint i = 0; i < totalDeployments; i++) {
            Deployment storage deployment = _deployments[i];

            if (deployment.synced) continue;

            if (bytes(deployment.contractABI).length != 0) {
                _syncVyperDeployments(deployment);
            } else if (bytes(deployment.forgeOutDir).length != 0) {
                _syncSolidityDeployments(deployment);
            } else {
                revert InvalidDeployment();
            }

            deployment.synced = true;
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
        cmds[2] = "--network"; cmds[3] = getChainIdAsString();
        cmds[4] = "--file"; cmds[5] = deployment.name;
        cmds[6] = "--address"; cmds[7] = vm.toString(deployment.addr);
        cmds[8] = "--out_dir"; cmds[9] = deployment.forgeOutDir;

        if (bytes(deployment.deploymentsSubDir).length != 0) {
            cmds[10] = "--deployments_sub_dir"; cmds[11] = deployment.deploymentsSubDir;
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
        cmds[2] = "--network"; cmds[3] = getChainIdAsString();
        cmds[4] = "--file"; cmds[5] = deployment.name;
        cmds[6] = "--address"; cmds[7] = vm.toString(deployment.addr);
        cmds[8] = "--bytecode"; cmds[9] = deployment.bytecode;
        cmds[10] = "--d_bytecode"; cmds[11] = deployment.deployedByteCode;
        cmds[12] = "--abi"; cmds[13] = deployment.contractABI;
        cmds[14] = "--compiler"; cmds[15] = deployment.compilerVersion;

        if (bytes(deployment.deploymentsSubDir).length != 0) {
            cmds[16] = "--deployments_sub_dir"; cmds[17] = deployment.deploymentsSubDir;
        }

        // run command
        vm.ffi(cmds);
    }
}
