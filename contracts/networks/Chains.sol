// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/StdChains.sol";

abstract contract Chains is StdChains {
    string public constant ANVIL_ALIAS = "anvil";
    string public constant MAINNET_ALIAS = "mainnet";
    string public constant GOERLI_ALIAS = "goerli";
    string public constant SEPOLIA_ALIAS = "sepolia";
    string public constant OPTIMISM_ALIAS = "optimism";
    string public constant OPTIMISM_GOERLI_ALIAS = "optimism_goerli";
    string public constant ARBITRUM_ONE_ALIAS = "arbitrum_one";
    string public constant ARBITRUM_ONE_GOERLI_ALIAS = "arbitrum_one_goerli";
    string public constant ARBITRUM_NOVE_ALIAS = "arbitrum_nova";
    string public constant POLYGON_ALIAS = "polygon";
    string public constant POLYGON_MUMBAI_ALIAS = "polygon_mumbai";
    string public constant AVALANCHE_ALIAS = "avalanche";
    string public constant AVALANCHE_FUJI_ALIAS = "avalanche_fuji";
    string public constant BNB_SMART_CHAIN_ALIAS = "bnb_smart_chain";
    string public constant BNB_SMART_CHAIN_TESTNET_ALIAS = "bnb_smart_chain_testnet";
    string public constant GNOSIS_CHAIN_ALIAS = "gnosis_chain";

    function getChainId() public view returns (uint256 id) {
        assembly { id := chainid() }
    }

    function getChainRpcUrl(string memory _alias) public returns (string memory) {
        return getChain(_alias).rpcUrl;
    }
}
