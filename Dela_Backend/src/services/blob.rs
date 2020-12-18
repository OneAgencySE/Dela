pub use blob::blob_handler_server::BlobHandlerServer;
use blob::{blob_handler_server::BlobHandler, ImageInfo, UploadImageRequest, UploadImageResponse};
use tonic::{Request, Response, Status, Streaming};

pub mod blob {
    tonic::include_proto!("blob");
}
#[derive(Debug, Default)]
pub struct BlobService {}

#[tonic::async_trait]
impl BlobHandler for BlobService {
    async fn upload_image(
        &self,
        stream: tonic::Request<Streaming<UploadImageRequest>>,
    ) -> Result<tonic::Response<UploadImageResponse>, Status> {
        todo!()
    }
}
