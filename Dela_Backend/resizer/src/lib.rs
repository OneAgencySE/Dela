use dotenv::dotenv;
use tonic::transport::Server;

mod bucket;
mod blob;
mod providers;
use providers::{ImageProvider, ImageServiceServer};
mod services;

/// This is the start of 'resizer' as a service. 
/// It's where we initialize the server and set up everything.
pub async fn run_resizer() -> Result<(), Box<dyn std::error::Error>> {
    let settings = init_settings();
    let addr = settings.img_prov_addr.parse()?;
    
    Server::builder()
        .add_service(ImageServiceServer::new(ImageProvider::new(&settings)))
        .serve(addr)
        .await?;
    
    Ok(())
}


fn init_settings() -> Settings {
    dotenv().ok();
    Settings {
        s3_endpoint: dotenv::var("S3_ENDPOINT").expect("Should have S3_ENDPOINT in environment"),
        s3_region: dotenv::var("S3_REGION").expect("Should have S3_REGION in environment"),
        img_prov_addr: dotenv::var("IMG_PROV_ADDR").expect("Should have IMG_PROV_ADDR in environment"),
    }
}

pub struct Settings {
    s3_endpoint: String,
    s3_region: String,
    img_prov_addr: String,
}