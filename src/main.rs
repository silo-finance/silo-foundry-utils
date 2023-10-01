mod commands;

use clap::{Subcommand, Parser};

use commands::deployments::sync::Sync;
use commands::key_val_json::read::KeyValJsonRead;
use commands::key_val_json::write::KeyValJson;

#[derive(Parser)]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Synchronize deployments
    Sync(Sync),
    /// Key-value JSON. Supports two keys {key1: {key2: value}}
    KeyValJson(KeyValJson),
    /// Read from the key-value JSON
    KeyValJsonRead(KeyValJsonRead)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli: Cli = Cli::parse();

    match &cli.command {
        Some(Commands::Sync(sync_inputs)) => {
            let result = sync_inputs.sync_deployments();

            match result {
                Ok(_) => { }
                Err(error) => { panic!("`sync` failed: {}", error); }
            }
        }
        Some(Commands::KeyValJson(save)) => {
            let result = save.save_value();

            match result {
                Ok(_) => { }
                Err(error) => { panic!("`write` failed: {}", error); }
            }
        }
        Some(Commands::KeyValJsonRead(read)) => {
            let result = read.read_value();

            match result {
                Ok(value) => {
                    println!("{:?}", value);
                }
                Err(error) => { panic!("`read` failed: {}", error); }
            }
        }
        None => {}
    }

    Ok(())
}
