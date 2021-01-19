use crate::Settings;
use services::BlobService;
use services::ServiceError;
use tokio::sync::mpsc;
use tonic::{Request, Response, Status, Streaming};
use tracing::{error, info};

pub mod blob {
    tonic::include_proto!("blob");
}
pub use blob::blob_handler_server::BlobHandlerServer;
use blob::{blob_data::Data, blob_handler_server::BlobHandler, BlobData, BlobInfo, FileInfo};

pub struct BlobProvider {
    blob_service: BlobService,
}

impl BlobProvider {
    pub fn new(settings: &Settings) -> Result<Self, ServiceError> {
        Ok(BlobProvider {
            blob_service: BlobService::new(settings.upload_path.clone())?,
        })
    }
}

/// This helped a lot: https://dev.to/anshulgoyal15/a-beginners-guide-to-grpc-with-rust-3c7o
#[tonic::async_trait]
impl BlobHandler for BlobProvider {
    type DownloadStream = mpsc::Receiver<Result<BlobData, Status>>;

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

    async fn download(
        &self,
        request: Request<BlobInfo>,
    ) -> Result<Response<Self::DownloadStream>, Status> {
        let (mut tx, rx) = mpsc::channel(5);
        let blob_id = request.into_inner().blob_id;
        info!("Requested download of: {}", &blob_id);

        let mut reader = self
            .blob_service
            .reader(&blob_id)
            .await
            .map_err(map_service_error)?;
        tokio::spawn(async move {
            while let Some(chunk) = reader.read().await.unwrap_or_else(|err| {
                error!("Service Error: {}", err);
                None
            }) {
                tx.send(Ok(BlobData {
                    data: Some(Data::ChunkData(chunk)),
                }))
                .await
                .unwrap_or_else(|err| {
                    error!("Send Error: {}", err);
                });
            }

            tx.send(Ok(BlobData {
                data: Some(Data::Info(FileInfo {
                    extension: ".jpeg".to_string(),
                    file_name: blob_id.to_string(),
                    meta_text: "Meta text".to_string(),
                })),
            }))
            .await
            .unwrap_or_else(|err| {
                error!("Send Error: {}", err);
            });

            info!("Download complete: {}", blob_id);
        });

        Ok(Response::new(rx))
    }
}

pub fn map_service_error(se: ServiceError) -> tonic::Status {
    Status::unavailable(format!("Service error: {}", se))
}
