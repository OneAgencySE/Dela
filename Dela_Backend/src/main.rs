use dotenv::dotenv;
use services::{BlobHandlerServer, BlobService, GreeterServer, MyGreeter};
use tonic::transport::Server;

mod services;

struct Settings {
    upload_path: String,
    server_addr: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
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
