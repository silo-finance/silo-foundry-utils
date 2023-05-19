mod commands;

use clap::{Subcommand, Parser};

use commands::sync::Sync;

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
        None => {}
    }

    Ok(())
}
