#![allow(non_snake_case)] // For structs that describe JSON files

use std::env;
use std::fs;
use std::path::PathBuf;
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use clap::Args;

#[derive(Args, Debug, Deserialize, Serialize, Clone, Default)]
pub struct KeyValJson {
    /// JSON file key 1
    #[arg(long = "key1")]
    pub key1: Option<String>,
    /// JSON file key 2
    #[arg(long = "key2")]
    pub key2: String,
    /// Complete file path
    #[arg(long = "file")]
    pub file: String,
    /// Any value
    #[arg(long = "value")]
    pub value: String
}

/*
This tool writes key-value pairs to JSON files with automatic sorting by keys.

Examples:
cargo run -- key-val-json \
    --key2 UniV3-ETH-USDC-0.3 \
    --file created-oracles.json \
    --value 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 \
    --key1 mainnet

cargo run -- key-val-json \
    --key2 UniV3-ETH-USDC-0.3 \
    --file created-oracles.json \
    --value 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

cargo run -- key-val-json \
    --key1 mainnet \
    --key2 UniV3-ETH-USDC-0.2 \
    --file created-oracles.json \
    --value 0xC03aaA39b223FE8D0A0e5C4F27eAD9083C756Cc3

Features:
- Supports both flat and nested JSON structures
- Automatically sorts all keys alphabetically when saving
- Recursively sorts nested objects
- Adds newline at end of file
*/
impl KeyValJson {
    pub fn save_value(&self) -> Result<(), Box<dyn std::error::Error>> {
        let result = self.save();

        match result {
            Ok(_) => { }
            Err(error) => { panic!("Failed to save address: {}", error); }
        }

        Ok(())
    }

    pub fn save(&self) -> Result<(), Box<dyn std::error::Error>> {
        let mut file_data = self.read_file()?;

        match &self.key1 {
            Some(key1) => {
                file_data[&key1][&self.key2] = Value::String(self.value.clone());
            }
            None => {
                file_data[&self.key2] = Value::String(self.value.clone());
            }
        }

        // Sort the JSON data by keys before writing
        let sorted_data = self.sort_json_by_keys(&file_data);

        let mut file_data = serde_json::to_string_pretty(&sorted_data).unwrap();
        file_data.push_str(&"\n".to_string());

        let result = std::fs::write(
            self.get_file_path()?,
            file_data,
        );

        match result {
            Ok(_) => { }
            Err(error) => { panic!("Failed to write to the file: {}", error); }
        }

        Ok(())
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
                let sorted_data = self.sort_json_by_keys(&Value::Object(data));
                std::fs::write(
                    file.clone(),
                    serde_json::to_string_pretty(&sorted_data).unwrap(),
                )?;
            },
        }

        Ok(file)
    }

    /// Recursively sort JSON objects by their keys alphabetically
    fn sort_json_by_keys(&self, value: &Value) -> Value {
        match value {
            Value::Object(map) => {
                let mut sorted_map = Map::new();
                let mut keys: Vec<_> = map.keys().collect();
                keys.sort(); // Sort keys alphabetically
                
                for key in keys {
                    let sorted_value = self.sort_json_by_keys(&map[key]);
                    sorted_map.insert(key.clone(), sorted_value);
                }
                
                Value::Object(sorted_map)
            }
            Value::Array(arr) => {
                let sorted_arr: Vec<Value> = arr.iter()
                    .map(|v| self.sort_json_by_keys(v))
                    .collect();
                Value::Array(sorted_arr)
            }
            _ => value.clone(), // For primitives (String, Number, Bool, Null), just clone
        }
    }
}
