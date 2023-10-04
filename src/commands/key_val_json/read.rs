#![allow(non_snake_case)] // For structs that describe JSON files

use std::env;
use std::fs;
use std::path::PathBuf;
use serde::{Deserialize, Serialize};
use serde_json::{Value};

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
    --key2 periodForAvgPrice \
    --file UniV3-ETH-USDC-0.3.json

cargo run -- key-val-json-read \
    --key2 periodForAvgPrice \
    --file UniV3-ETH-USDC-0.3.json

cargo run -- key-val-json-read \
    --key2 UniV3-ETH-USDC-0.2 \
    --file created-oracles.json
*/
impl KeyValJsonRead {
    pub fn read_value(&self) -> Result<String, Box<dyn std::error::Error>> {
        let result;

        let file_path = self.get_file_path()?;

        match fs::metadata(&file_path) {
            Ok(_) => {
                let file_data = self.read_file(file_path)?;

                match &self.key1 {
                    Some(key1) => {
                        if file_data[&key1][&self.key2].is_number() {
                            result = file_data[&key1][&self.key2].as_f64().unwrap().to_string();
                        } else if file_data[&key1][&self.key2].is_boolean() {
                            result = file_data[&key1][&self.key2].as_bool().unwrap().to_string();
                        } else {
                            match  file_data[&key1][&self.key2].as_str() {
                                Some(value) => {
                                    result = value.to_string();
                                }
                                None => {
                                    result = "".to_string();
                                }
                            }
                        }
                    }
                    None => {
                        if file_data[&self.key2].is_number() {
                            result = file_data[&self.key2].as_f64().unwrap().to_string();
                        } else if file_data[&self.key2].is_boolean() {
                            result = file_data[&self.key2].as_bool().unwrap().to_string();
                        } else {
                            match file_data[&self.key2].as_str() {
                                Some(value) => {
                                    result = value.to_string();
                                }
                                None => {
                                    result = "".to_string();
                                }
                            }
                        }
                        
                    }
                }
            },
            Err(_) => {
                result = "".to_string()
            },
        }

        Ok(result.to_string())
    }

    fn read_file(&self, file: PathBuf) -> Result<Value, Box<dyn std::error::Error>> {
        let data = fs::read_to_string(file)
            .expect("Unable to read file");

        let json: Value = serde_json::from_str(&data)
            .expect("JSON was not well-formatted");

        Ok(json)
    }

    fn get_file_path(&self) -> Result<PathBuf, Box<dyn std::error::Error>> {
        let current_dir = env::current_dir().unwrap();

        Ok(current_dir.join(self.file.clone()))
    }
}
