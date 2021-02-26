use crate::{Settings, services::BlobService};
use async_stream::try_stream;
use futures::Stream;
use futures::io::Read;

use std::pin::Pin;
use tonic::{Request, Response, Status, Streaming};
use tracing::{error, info};

pub mod blob {
    tonic::include_proto!("blob");
}
pub use blob::blob_handler_server::BlobHandlerServer;
use blob::{blob_data::Data, blob_handler_server::BlobHandler, BlobData, BlobInfo, FileInfo};

#[derive(Debug)]
pub struct BlobProvider {
    blob_service: BlobService,
}

impl BlobProvider {
    pub fn new(settings: &Settings) -> Self {
        BlobProvider {
            blob_service: BlobService::new(settings.upload_path.clone()).unwrap(),
        }
    }
}

#[tonic::async_trait]
impl BlobHandler for BlobProvider {
    type DownloadStream =
        Pin<Box<dyn Stream<Item = Result<BlobData, Status>> + Send + Sync + 'static>>;

    #[tracing::instrument]
    async fn download(
        &self,
        request: Request<BlobInfo>,
    ) -> Result<Response<Self::DownloadStream>, Status> {
        let blob_id = request.into_inner().blob_id;
        info!("Requested download of: {}", &blob_id);
        let service = self.blob_service.clone();


        let mut stream =
        service.reader(&blob_id)
        .await
        .map_err(map_service_error)?;

        let m = stream.read::<Option<Vec<u8>>>().await.unwrap();

        let output = try_stream! {
            let mut stream =
                service.reader(&blob_id)
                .await
                .map_err(map_service_error)?;

            while let Some(chunk) = stream.read::<Option<Vec<u8>>>().await
                .unwrap_or_else(|err| { error!("Service Error: {}", err); None })
            {
                yield BlobData { data: Some(Data::ChunkData(chunk)), };
            }

            yield BlobData {
                data: Some(
                    Data::Info(
                        FileInfo {
                            extension: ".jpeg".to_string(),
                            file_name: blob_id.to_string(),
                            meta_text: "Meta text".to_string(),
                        }
                    )
                )
            };
        };

        Ok(Response::new(Box::pin(output) as Self::DownloadStream))
    }

    #[tracing::instrument]
    async fn upload(
        &self,
        stream: Request<Streaming<BlobData>>,
    ) -> Result<Response<BlobInfo>, Status> {
        info!("Uploading image to server");

        let mut blob = self
            .blob_service
            .writer()
            .create_blob()
            .await
            .map_err(map_service_error)?;

        let mut file_info: Option<FileInfo> = None;
        let mut s = stream.into_inner();
        while let Some(req) = s.message().await? {
            if let Some(d) = req.data {
                match d {
                    Data::Info(info) => file_info = Some(info),
                    Data::ChunkData(chunk) => {
                        blob.append(chunk).await.map_err(map_service_error)?
                    }
                }
            }
        }

        match file_info {
            Some(f) => {
                let blob_id = blob
                    .finalize(&f.extension)
                    .await
                    .map_err(map_service_error)?;
                info!("Upload finished, file {}", &blob_id);
                Ok(Response::new(BlobInfo { blob_id }))
            }
            None => {
                info!("No FileInfo received, aborting");
                blob.abort().await.map_err(map_service_error)?;
                Err(tonic::Status::aborted("No FileInfo was received!"))
            }
        }
    }
}

pub fn map_service_error<E: std::error::Error>(se: E) -> tonic::Status {
    Status::unavailable(format!("Service error: {}", se))
}
