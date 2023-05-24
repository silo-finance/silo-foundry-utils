use std::env;
use std::fs;
use std::path::PathBuf;
use serde::{Deserialize, Serialize};
use serde_json::{from_str, Value};

use clap::{Args};

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct AbiJSON {
    pub address: String,
    pub abi: Vec<Value>,
    pub bytecode: String,
    pub deployed_bytecode: String,
    pub compiler: String
}

#[derive(Args, Debug, Deserialize, Serialize, Clone, Default)]
pub struct Sync {
    /// Network identifier
    #[arg(long = "network")]
    pub network: String,
    /// Directory
    #[arg(long = "deployments_sub_dir")]
    pub deployments_sub_dir: Option<String>,
    /// Relative file path
    #[arg(long = "file")]
    pub file: String,
    /// Deployed contract address
    #[arg(long = "address")]
    pub address: String,
    /// Bytecode of the deployed smart contract
    #[arg(long = "bytecode")]
    pub bytecode: Option<String>,
    /// Deployed bytecode of the deployed smart contact
    #[arg(long = "d_bytecode")]
    pub deployed_bytecode: Option<String>,
    /// Smart contract ABI
    #[arg(long = "abi")]
    pub abi: Option<String>,
    /// Compiler version
    #[arg(long = "compiler")]
    pub compiler_version: Option<String>
}
/**
 Example:
 cargo run -- sync \
    --network 31337 \
    --file Counter.vy.json \
    --deployments_sub_dir some-dir \
    --address 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
    --bytecode 0x346100d5576020...00000000000064 \
    --d_bytecode 0x6003361161...0657283000307000b \
    --abi '[{"stateMutability": "nonpayable", "type": "constructor", "inputs": [{"name": "_mult", "type": "uint256"}]}]' \
    --compiler 0.3.7+commit.6020b8b
*/
impl Sync {
    pub fn sync_deployments(&self) -> Result<(), Box<dyn std::error::Error>> {
        let result = self.save();

        match result {
            Ok(_) => { }
            Err(error) => { panic!("Failed to save artifacts: {}", error); }
        }

        Ok(())
    }

    fn  save(&self) -> Result<(), Box<dyn std::error::Error>> {
        let deployments_dir = self.resolve_deployments_dir().unwrap();

        let mut file_name: String = self.file.clone();
        file_name.push_str(&".json".to_string());

        let file_path = deployments_dir.join(file_name);

        let abi = &self.abi.clone().unwrap();

        let result: AbiJSON = AbiJSON {
            address: self.address.clone(),
            abi: from_str(abi).expect("Unable to parse ABI"),
            bytecode: self.bytecode.clone().unwrap(),
            deployed_bytecode: self.deployed_bytecode.clone().unwrap(),
            compiler: self.compiler_version.clone().unwrap()
        };

        let result = std::fs::write(
            file_path,
            serde_json::to_string_pretty(&result).unwrap(),
        );

        match result {
            Ok(_) => { }
            Err(error) => { panic!("Failed to write to the file: {}", error); }
        }

        Ok(())
    }

    fn resolve_deployments_dir(&self) -> Result<PathBuf, Box<dyn std::error::Error>> {
        let mut deployments_dir = env::current_dir().unwrap();

        match &self.deployments_sub_dir {
            Some(deployments_sub_dir) => {
                deployments_dir = deployments_dir.join(deployments_sub_dir);
            }
            None => {}
        }

        deployments_dir = deployments_dir.join("deployments").join(&self.network);

        println!("{}", deployments_dir.display());

        if !deployments_dir.is_dir() {
            let result = fs::create_dir_all(&deployments_dir);

            match result {
                Ok(_) => { }
                Err(error) => { panic!("Failed to create `deployments` directory: {}", error); }
            }
        }

        Ok(deployments_dir)
    } 
}
