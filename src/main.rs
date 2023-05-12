mod commands;

use clap::{Subcommand, Parser};

#[derive(Parser)]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
}

fn main() {
    let cli: Cli = Cli::parse();
}
