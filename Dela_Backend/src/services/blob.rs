pub use blob::blob_handler_server::BlobHandlerServer;
use blob::{
    blob_handler_server::BlobHandler, upload_image_request::Data, UploadImageRequest,
    UploadImageResponse,
};
use std::fs::File;
use std::io::prelude::*;
use tonic::{Response, Status, Streaming};

pub mod blob {
    tonic::include_proto!("blob");
}
#[derive(Debug, Default)]
pub struct BlobService {}

/// This helped a lot: https://dev.to/anshulgoyal15/a-beginners-guide-to-grpc-with-rust-3c7o
#[tonic::async_trait]
impl BlobHandler for BlobService {
    async fn upload_image(
        &self,
        stream: tonic::Request<Streaming<UploadImageRequest>>,
    ) -> Result<tonic::Response<UploadImageResponse>, Status> {
        println!("Woo");
        let mut file: File = match std::fs::File::open("foo.png") {
            Ok(f) => f,
            Err(_) => std::fs::File::create("foo.png").unwrap(),
        };

        let mut s = stream.into_inner();
        while let Some(req) = s.message().await? {
            if let Some(d) = req.data {
                // Guard
                match d {
                    Data::Info(info) => println!("File info! {}", info.image_type),
                    Data::ChunkData(chunk) => {
                        file.write_all(&chunk)?;
                    }
                }
            }
        }

        file.sync_all()?;
        Ok(Response::new(UploadImageResponse {
            fetch_url: String::from("foo"),
        }))
    }
}
