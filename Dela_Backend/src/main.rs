use dotenv::dotenv;
use providers::{BlobHandlerServer, BlobProvider, FeedHandlerServer, FeedProvider};
use tonic::transport::Server;

use tracing::Level;
use tracing_subscriber::FmtSubscriber;

mod providers;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .finish();
    tracing::subscriber::set_global_default(subscriber).expect("setting default subscriber failed");

    let settings = init_settings();

    Server::builder()
        .add_service(BlobHandlerServer::new(BlobProvider::new(&settings)))
        .add_service(FeedHandlerServer::new(FeedProvider::new(&settings)))
        .serve(settings.server_addr.parse()?)
        .await?;

    Ok(())
}

fn init_settings() -> Settings {
    dotenv().ok();
    Settings {
        upload_path: dotenv::var("UPLOAD_PATH").expect("Should have UPLOAD_PATH in environment"),
        server_addr: dotenv::var("SERVER_ADDR").expect("Should have SERVER_ADDR in environment"),
    }
}

pub struct Settings {
    upload_path: String,
    server_addr: String,
}
