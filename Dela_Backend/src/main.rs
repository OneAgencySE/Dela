use dotenv::dotenv;
use services::{BlobHandlerServer, BlobService, GreeterServer, MyGreeter};
use tonic::transport::Server;

use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

mod services;

struct Settings {
    upload_path: String,
    server_addr: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .finish();
    tracing::subscriber::set_global_default(subscriber).expect("setting default subscriber failed");

    let settings = init_settings();
    let greeter = MyGreeter::default();
    let blob_service = BlobService::new(&settings.upload_path);

    Server::builder()
        .add_service(BlobHandlerServer::new(blob_service))
        .add_service(GreeterServer::new(greeter))
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
