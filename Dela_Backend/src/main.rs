mod services;
use services::{BlobHandlerServer, BlobService, GreeterServer, MyGreeter};
use tonic::transport::Server;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr = "0.0.0.0:50051".parse()?;
    let greeter = MyGreeter::default();
    let blob_service = BlobService::default();

    Server::builder()
        .add_service(BlobHandlerServer::new(blob_service))
        .add_service(GreeterServer::new(greeter))
        .serve(addr)
        .await?;

    Ok(())
}
