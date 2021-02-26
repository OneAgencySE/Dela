use crate::{Settings, blob::Blob, bucket::Bucket, blob::TEMP_DIR, services::{ImageResizer, S3Storage}};
use futures::Stream;

use std::{pin::Pin, sync::Arc};
use tonic::{Request, Response, Status, Streaming};
use futures_util::StreamExt;


pub mod imageservice {
    tonic::include_proto!("imageservice");
}

pub use imageservice::image_service_server::ImageServiceServer;
pub use imageservice::image_info::Quality;
use imageservice::{image_service_server::ImageService, Image, ImageInfo, ImageStatus};

pub struct ImageProvider {
    storage: Arc<S3Storage>,
}

impl ImageProvider {
    pub fn new(settings: &Settings) -> Self {
        std::fs::create_dir(TEMP_DIR).expect("Unable to create a Temp folder");

        ImageProvider{
            storage: Arc::new(S3Storage::new(settings)),
        }
    }
}

#[tonic::async_trait]
impl ImageService for ImageProvider {
    type DownloadStream = Pin<Box<dyn Stream<Item = Result<Image, Status>> + Send + Sync + 'static>>;

    async fn download(
        &self,
        request: Request<ImageInfo>,
    ) -> Result<Response<Self::DownloadStream>, Status> {
        let image_info = request.into_inner();
        let bucket = Bucket::from_img_quality(image_info.quality);
        let storage = Arc::clone(&self.storage);

        let stream = storage.download(bucket, image_info.image_id).await.unwrap();
        let mapped= stream.map(|x| 
            x.map(|b| Image{  extension: ".png".to_string(), chunk_data: b.to_vec() })
                .map_err(|e| Status::aborted(format!("Fatal: {}", e.to_string())))
        );

        Ok(Response::new(Box::pin(mapped) as Self::DownloadStream))
    }

    async fn upload(&self, request: Request<Streaming<Image>>) -> Result<Response<ImageStatus>, Status> {

        let mut extension: Option<String> = None;

        let storage = Arc::clone(&self.storage);
        
        // Store file to disk
        let mut stream = request.into_inner();
        let mut main_blob = Blob::new().await?;
        while let Some(blob) = stream.message().await? {
            extension = Some(blob.extension);
            main_blob.append(&blob.chunk_data[..]).await?;
        }
        if let Some(ex) = extension {
            main_blob.finalize(&ex).await?;
        }

        let image_id = format!("{}.png", uuid::Uuid::new_v4());
        // Resize images
        let orig = ImageResizer::resize(&mut main_blob, Quality::Original).await?;
        storage.upload(Bucket::OriginalImage, &image_id, orig.into_stream()).await
            .map_err(|e| Status::internal(e.to_string()))?;
        
        let web = ImageResizer::resize(&mut main_blob,Quality::Web).await?;
        storage.upload(Bucket::WebImage, &image_id, web.into_stream()).await
            .map_err(|e| Status::internal(e.to_string()))?;

        let phone = ImageResizer::resize(&mut main_blob,Quality::Phone).await?;
        storage.upload(Bucket::WebImage, &image_id, phone.into_stream()).await
            .map_err(|e| Status::internal(e.to_string()))?;

        let thumbnail = ImageResizer::resize(&mut main_blob, Quality::Thumbnail).await?;
        storage.upload(Bucket::Thumbnail, &image_id, thumbnail.into_stream()).await
            .map_err(|e| Status::internal(e.to_string()))?;

        Ok(Response::new(ImageStatus { image_id }))
    }
}
