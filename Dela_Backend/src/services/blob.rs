pub use blob::blob_handler_server::BlobHandlerServer;
use blob::{
    blob_handler_server::BlobHandler, upload_image_request::Data, UploadImageRequest,
    UploadImageResponse,
};
use std::fs::File;
use std::io::prelude::*;
use tonic::{Response, Status, Streaming};
use uuid::Uuid;

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

        let guid = Uuid::new_v4().to_string();
        let mut file_ext: Option<String> = None;

        let mut file: File = match std::fs::File::open(&guid) {
            Ok(f) => f,
            Err(_) => std::fs::File::create(&guid).unwrap(),
        };

        let mut s = stream.into_inner();
        while let Some(req) = s.message().await? {
            if let Some(d) = req.data {
                match d {
                    Data::Info(info) => file_ext = Some(info.extension),
                    Data::ChunkData(chunk) => {
                        file.write_all(&chunk)?;
                    }
                }
            }
        }
        file.sync_all()?;

        if let Some(f) = file_ext {
            let _ = std::fs::rename(&guid, format!("{}{}", &guid, f).as_str()).unwrap();
        }

        Ok(Response::new(UploadImageResponse {
            fetch_url: String::from("foo"),
        }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use blob::{
        blob_handler_client::BlobHandlerClient, ImageInfo, UploadImageRequest, UploadImageResponse,
    };
    use dotenv::dotenv;
    use futures::stream::iter;

    pub mod blobtest {
        tonic::include_proto!("blob");
    }

    async fn upload_image(path: &str) -> Result<UploadImageResponse, Box<dyn std::error::Error>> {
        let mut file = std::fs::File::open(path).expect("File did not exist!!");
        let mut client = BlobHandlerClient::connect("http://0.0.0.0:50051").await?;

        let mut bif = Vec::new();
        file.read_to_end(&mut bif).expect("Read did not work");
        let mut arr: Vec<UploadImageRequest> = bif
            .chunks(1024)
            .map(|x| UploadImageRequest {
                data: Some(Data::ChunkData(x.into())),
            })
            .collect();

        arr.push(UploadImageRequest {
            data: Some(Data::Info(ImageInfo {
                extension: ".jpeg".to_string(),
                meta_text: "Smooth".to_string(),
            })),
        });

        let request = tonic::Request::new(iter(arr));
        let res = client.upload_image(request).await?;

        Ok(res.into_inner())
    }

    #[tokio::test(core_threads = 1)]
    async fn upload() {
        dotenv().ok();

        let file = dotenv::var("TEST_JPEG").unwrap();
        let res = upload_image(&file).await.unwrap();
        assert_eq!(res.fetch_url, "foo".to_string())
    }
}
