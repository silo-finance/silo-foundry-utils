// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Vyper.sol";

contract Deployer is VyperDeployer {
    /// @dev The developer can operate from scripts if it is needed to synchronize deployments.
    /// For example, deployments synchronization should be disabled in tests but enabled in scripts.
    bool public deploymentsSyncDisabled;

    /// @dev The struct that describes the deployment
    struct Deployment {
        string name; // The name of the smart contract with an extension: `Counter.vy`
        string deploymentsSubDir; // The directory for the ABI allocation `deploymentsSubDir/deployments/<network>`
        string bytecode; // The bytecode of the deployed smart contract
        string deployedByteCode; // The deployed bytecode of the deployed smart contract
        string contractABI; // An ABI of the deployed smart contract
        string compilerVersion; // The compiler version
        address addr; // The address of the deployed smart contract
        bool synced; // The flag shows whether the smart contract is already synced or not
    }

    /// @dev The list of the deployments
    Deployment[] private deployments;

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
        assembly { currentChainID := chainid() }
        chainIdAsString = vm.toString(currentChainID);
    }

    /// @notice Deploy smart contract
    /// @param _folder The smart contract allocation folder
    /// @param _deploymentsSubDir The directory for the ABI allocation
    /// @param _fileName The smart contract file name with an extension: `Counter.vy`
    /// @return deployedAddress An address of the deployed smart contract
    function _deploy(
        string memory _folder,
        string memory _deploymentsSubDir,
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

        deployments.push(Deployment({
            name: _fileName,
            deploymentsSubDir: _deploymentsSubDir,
            addr: deployedAddress,
            bytecode: bytecode,
            deployedByteCode: deployedByteCode,
            contractABI: contractABI,
            compilerVersion: compilerVersion,
            synced: false
        }));

        return deployedAddress;
    }

    /// @notice Synchronize deployments by calling an external script
    function _syncDeployments() internal {
        if (deploymentsSyncDisabled) return;

        uint256 totalDeployments = deployments.length;

        for (uint i = 0; i < totalDeployments; i++) {
            Deployment storage deployment = deployments[i];

            if (deployment.synced) continue;

            string memory contractABI = deployment.contractABI;

            if (bytes(contractABI).length != 0) {
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

                deployment.synced = true;
            }
        }
    }
}
