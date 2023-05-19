#!/bin/bash

cargo build --release --verbose
cp target/release/silo-foundry-utils ./silo-foundry-utils
