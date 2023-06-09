# Vyper deployer

1. The `vyper` compiler should be installed and available via `vyper` command
    [vyper compiler installation](https://docs.vyperlang.org/en/stable/installing-vyper.html)

1. Writing the deployment script. [See an example](./../test/deployer/deployments-scripts/VyperCounterDeploy.s.sol):
    ```solidity
    import "silo-foundry-utils/deployer/Deployer.sol";

    contract VyperCounterDeploy is Deployer {
        string internal constant DEPLOYMENTS_SUB_DIR = "";
        string internal constant BASE_DIR = "test/deployer/mocks";
        string internal constant FILE = "Counter.vy";

        function setUp() public {}

        function run() public returns (address counter) {
            // compiles and deploys `Counter.vy` smart contract
            _deploy(BASE_DIR, DEPLOYMENTS_SUB_DIR, FILE, abi.encodePacked(100));
            // synchronize the deployments results into the `deployments/<chain_id>` folder
            _syncDeployments();
        }
    }
    ```

1. Run the deployment script:
    ```bash
    # forge script test/deployer/deployments-scripts/VyperCounterDeploy.s.sol --ffi
    forge script <relative_path> --ffi
    ```
