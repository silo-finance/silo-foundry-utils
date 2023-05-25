# Silo-Foundry Utilities [NOT PRODUCTION READY]

## Installation

1. Add the silo-foundry-utils package (assuming that you are in the forge project)

   ```bash
   forge install silo-finance/silo-foundry-utils
   ```

1. Add to .gitignore

   ```bash
   cat >> .gitignore <<EOF

   # silo-foundry-utils
   /deployments/localhost
   /deployments/31337

   # silo-foundry-utils cli binary
   /silo-foundry-utils
   EOF
   ```

1. Build the cli directly from lib/silo-foundry-utils

   ```bash
   cd lib/silo-foundry-utils
   cargo build --release
   cp target/release/silo-foundry-utils ../../silo-foundry-utils
   ```

   This way you can then execute it via the following:

   ```bash
   ./silo-foundry-utils <command>
   ```

1. Update `remappings.txt`, add:
   ```bash
   silo-foundry-utils/=lib/silo-foundry-utils/contracts/
   ```

## Run tests

1. Build silo foundry utils

   ```bash
   ./bash/build-for-tests.sh
   ```

1. Run tests with `forge`

   ```bash
   forge test --ffi -vvv && ./bash/kill-anvil.sh
   ```

## Utilities

* [Vyper deployer](docs/vyper-depolyer.md)
