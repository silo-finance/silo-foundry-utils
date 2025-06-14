#![allow(non_snake_case)] // For structs that describe JSON files

use std::env;
use std::fs;
use std::path::PathBuf;
use serde::{Deserialize, Serialize};
use serde_json::{from_str, Value};

use clap::Args;

enum Languages {
    Vyper,
    Solidity
}

impl Languages {
    fn as_str(&self) -> String {
        match self {
            Languages::Vyper => "Vyper".to_string(),
            Languages::Solidity => "Solidity".to_string()
        }
    }
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct DeploymentJSON {
    pub address: String,
    pub abi: Vec<Value>,
    pub bytecode: String,
    pub deployedBytecode: String,
    pub language: String,
    pub compiler: String,
    #[serde(skip_serializing_if = "is_zero_or_none")]
    pub deployedAtBlock: Option<u64>,
}

fn is_zero_or_none(value: &Option<u64>) -> bool {
    match value {
        None => true,
        Some(0) => true,
        Some(_) => false,
    }
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct OutFileBytecode {
    pub object: String,
    pub sourceMap: String,
    pub linkReferences: Value
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct OutFileCompiler {
    pub version: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct OutFileMetadata {
    pub compiler: OutFileCompiler,
    pub language: String,
    pub settings: Value,
    pub sources: Value,
    pub version: u64,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct OutFileData {
    pub abi: Vec<Value>,
    pub bytecode: OutFileBytecode,
    pub deployedBytecode: OutFileBytecode,
    pub methodIdentifiers: Value,
    pub rawMetadata: String,
    pub metadata: OutFileMetadata,
    pub id: u64,
}

#[derive(Args, Debug, Deserialize, Serialize, Clone, Default)]
pub struct Sync {
    /// Network identifier
    #[arg(long = "network")]
    pub network: String,
    /// Directory
    #[arg(long = "deployments_sub_dir")]
    pub deployments_sub_dir: Option<String>,
    /// Foundry `out` directory
    #[arg(long = "out_dir")]
    pub out_dir: Option<String>,
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
    pub compiler_version: Option<String>,
    /// Deployed at block
    #[arg(long = "deployed_at_block")]
    pub deployed_at_block: Option<u64>
}
/**
 Example vyper:
 cargo run -- sync \
    --network 31337 \
    --file Counter.vy.json \
    --deployments_sub_dir some-dir \
    --address 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
    --bytecode 0x346100d5576020...00000000000064 \
    --d_bytecode 0x6003361161...0657283000307000b \
    --abi '[{"stateMutability": "nonpayable", "type": "constructor", "inputs": [{"name": "_mult", "type": "uint256"}]}]' \
    --compiler 0.3.7+commit.6020b8b

Example Solidity:
cargo run -- sync \
    --network 31337 \
    --out_dir out \
    --file Counter.sol \
    --address 0x5FbDB2315678afecb367f032d93F642f64180aa3
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
        
        let result: DeploymentJSON;

        match &self.out_dir {
            Some(_) => {
                result = self.deployment_json_solidity().unwrap();
            }
            None => {
                result = self.deployment_json_vyper().unwrap();
            }
        }

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

    fn deployment_json_vyper(&self) -> Result<DeploymentJSON, Box<dyn std::error::Error>> {
        let abi = &self.abi.clone().unwrap();
 
        Ok(DeploymentJSON {
            address: self.address.clone(),
            abi: from_str(abi).expect("Unable to parse ABI"),
            bytecode: self.bytecode.clone().unwrap(),
            deployedBytecode: self.deployed_bytecode.clone().unwrap(),
            language: Languages::Vyper.as_str(),
            compiler: self.compiler_version.clone().unwrap(),
            deployedAtBlock: self.deployed_at_block
        })
    }

    fn deployment_json_solidity(&self) -> Result<DeploymentJSON, Box<dyn std::error::Error>> {
        let out_dir = self.out_dir.clone().unwrap();
        let file_dir_name = self.file.clone();
        let file_dir_name_parts: Vec<&str> = file_dir_name.split(".").collect();
        let mut file_name: String = file_dir_name_parts[0].to_string();
        file_name.push_str(&".json".to_string());

        let json_path = env::current_dir()
            .unwrap()
            .join(out_dir)
            .join(file_dir_name)
            .join(file_name);

        let data = fs::read_to_string(&json_path).expect("Unable to read `out` JSON file");
        let out_file: OutFileData = from_str(&data).expect("Unable to parse ABI JSON");

        Ok(DeploymentJSON {
            address: self.address.clone(),
            abi: out_file.abi,
            bytecode: out_file.bytecode.object,
            deployedBytecode: out_file.deployedBytecode.object,
            language: Languages::Solidity.as_str(),
            compiler: out_file.metadata.compiler.version,
            deployedAtBlock: self.deployed_at_block
        })
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
