use dotenv::dotenv;
use providers::{BlobHandlerServer, BlobProvider, FeedHandlerServer, FeedProvider};
use resizer::run_resizer;
use tonic::transport::Server;

use tracing::info;

mod providers;
mod services;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {

    // run_resizer().await?;


    tracing_subscriber::fmt()
    .with_max_level(tracing::Level::INFO)
    .init();
    
    let settings = init_settings();
    let addr = settings.server_addr.parse()?;
    info!("Dela Backend is running at: {}", &addr);
    
    Server::builder()
        .add_service(BlobHandlerServer::new(BlobProvider::new(&settings)))
        .add_service(FeedHandlerServer::new(FeedProvider::new(&settings)))
        .serve(addr)
        .await?;
    
    Ok(())
}

fn init_settings() -> Settings {
    dotenv().ok();
    Settings {
        upload_path: dotenv::var("UPLOAD_PATH").expect("Should have UPLOAD_PATH in environment"),
        server_addr: dotenv::var("DELA_PROV_ADDR").expect("Should have DELA_PROV_ADDR in environment"),
    }
}

pub struct Settings {
    upload_path: String,
    server_addr: String,
}
