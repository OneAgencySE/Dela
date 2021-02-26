
/// This is simply a separate runner for the 'resizer' service. 
/// to run it you need to supply all needed enviromental variables

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    resizer::run_resizer().await?;
    Ok(())
}
