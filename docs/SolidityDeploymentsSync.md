# Solidity deployments synchronization

1. Writing the deployment script. [See an example](./../test/deployer/deployments-scripts/SolidityCounterDeploy.s.sol):
    ```solidity
    import "silo-foundry-utils/deployer/Deployer.sol";

    contract SolidityCounterDeploy is Deployer {
        string internal constant DEPLOYMENTS_SUB_DIR = "";
        string internal constant FORGE_OUT_DIR = "out";
        string internal constant FILE = "Counter.sol";

        uint256 public testMultiplier = 111;

        function setUp() public {}

        function run() public returns (address counter) {
            // deploys `Counter.sol` smart contract
            counter = address(new Counter(testMultiplier));
            // register deployment in the `Deployer` for the synchronization
            _registerDeployment(counter, DEPLOYMENTS_SUB_DIR, FORGE_OUT_DIR, COUNTER_SOL);
            // synchronize the deployments results into the `deployments/<chain_id>` folder
            _syncDeployments();
        }
    }
    ```

1. Run the deployment script:
    ```bash
    # forge script test/deployer/deployments-scripts/SolidityCounterDeploy.s.sol --ffi
    forge script <relative_path> --ffi
    ```
