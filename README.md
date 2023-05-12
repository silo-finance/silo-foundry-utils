# Silo-Foundry Utilities

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
   /sfu
   EOF
   ```

1. Build the cli directly from lib/silo-foundry-utils

   ```bash
   cd lib/silo-foundry-utils
   cargo build --release
   cp target/release/silo-foundry-utils ../../sfu
   ```

   This way you can then execute it via the following:

   ```bash
   ./sfu <command>
   ```
