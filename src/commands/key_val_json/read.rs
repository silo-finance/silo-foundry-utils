#![allow(non_snake_case)] // For structs that describe JSON files

use std::env;
use std::fs;
use std::path::PathBuf;
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use clap::Args;

#[derive(Args, Debug, Deserialize, Serialize, Clone, Default)]
pub struct KeyValJsonRead {
    /// JSON file key 1
    #[arg(long = "key1")]
    pub key1: Option<String>,
    /// JSON file key 2
    #[arg(long = "key2")]
    pub key2: String,
    /// Complete file path
    #[arg(long = "file")]
    pub file: String,
}

/*
cargo run -- key-val-json-read \
    --key1 mainnet \
    --key2 UniV3-ETH-USDC-0.3 \
    --file created-oracles.json

cargo run -- key-val-json-read \
    --key2 UniV3-ETH-USDC-0.3 \
    --file created-oracles.json

cargo run -- key-val-json-read \
    --key2 UniV3-ETH-USDC-0.2 \
    --file created-oracles.json
*/
impl KeyValJsonRead {
    pub fn read_value(&self) -> Result<String, Box<dyn std::error::Error>> {
        let result;
        let file_data = self.read_file()?;

        match &self.key1 {
            Some(key1) => {
                result = file_data[&key1][&self.key2].as_str().unwrap();
            }
            None => {
                result = file_data[&self.key2].as_str().unwrap();
            }
        }

        Ok(result.to_string())
    }

    fn read_file(&self) -> Result<Value, Box<dyn std::error::Error>> {
        let deployments_file = self.get_file_path()?;

        let data = fs::read_to_string(deployments_file)
            .expect("Unable to read file");

        let json: Value = serde_json::from_str(&data)
            .expect("JSON was not well-formatted");

        Ok(json)
    }

    fn get_file_path(&self) -> Result<PathBuf, Box<dyn std::error::Error>> {
        let current_dir = env::current_dir().unwrap();
        let file = current_dir.join(self.file.clone());

        match fs::metadata(&file) {
            Ok(_) => {},
            Err(_) => {
                let data = Map::new();
                std::fs::write(
                    file.clone(),
                    serde_json::to_string_pretty(&Value::Object(data)).unwrap(),
                )?;
            },
        }

        Ok(file)
    }
}
