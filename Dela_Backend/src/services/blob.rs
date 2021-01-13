pub use blob::blob_handler_server::BlobHandlerServer;
use blob::{blob_data::Data, blob_handler_server::BlobHandler, BlobData, BlobInfo, FileInfo};
use tokio::{fs::File, io::AsyncReadExt, io::AsyncWriteExt, sync::mpsc};
use tonic::{Request, Response, Status, Streaming};
use uuid::Uuid;

pub mod blob {
    tonic::include_proto!("blob");
}
#[derive(Debug)]
pub struct BlobService {
    output_path: String,
}

impl BlobService {
    pub fn new(upload_path: &str) -> Self {
        let service = BlobService {
            output_path: upload_path.to_string(),
        };
        service.validate_path(upload_path);
        service
    }

    fn validate_path(&self, upload_path: &str) {
        std::fs::read_dir(upload_path).unwrap();
    }
}

/// This helped a lot: https://dev.to/anshulgoyal15/a-beginners-guide-to-grpc-with-rust-3c7o
#[tonic::async_trait]
impl BlobHandler for BlobService {
    type DownloadStream = mpsc::Receiver<Result<BlobData, Status>>;

    async fn upload(
        &self,
        stream: Request<Streaming<BlobData>>,
    ) -> Result<Response<BlobInfo>, Status> {
        let mut file_name = Uuid::new_v4().to_string();
        let path = format!("{}/{}", &self.output_path, file_name);
        let mut file_ext: Option<String> = None;

        let mut file = File::create(&path).await?;
        let mut s = stream.into_inner();

        while let Some(req) = s.message().await? {
            if let Some(d) = req.data {
                match d {
                    Data::Info(info) => file_ext = Some(info.extension),
                    Data::ChunkData(chunk) => {
                        file.write_all(&chunk).await?;
                    }
                }
            }
        }
        file.sync_all().await?;

        if let Some(ext) = file_ext {
            file_name.push_str(&ext);
            std::fs::rename(&path, format!("{}{}", &path, ext).as_str()).unwrap();
            Ok(Response::new(BlobInfo { blob_id: file_name }))
        } else {
            tokio::fs::remove_file(&path).await?;
            Err(tonic::Status::aborted("No FileInfo was received!"))
        }
    }

    async fn download(
        &self,
        request: Request<BlobInfo>,
    ) -> Result<Response<Self::DownloadStream>, Status> {
        let (mut tx, rx) = mpsc::channel(5);
        let file_name = request.into_inner().blob_id;
        let blob_path = format!("{}/{}", self.output_path, &file_name);

        tokio::spawn(async move {
            let file: tokio::fs::File = tokio::fs::File::open(blob_path).await.unwrap();
            //.map_err(|_e| tonic::Status::unavailable("File does not exist"))?;

            let mut buffer = [0; 1024];
            let mut stream = tokio::io::BufStream::new(file);

            while stream.read(&mut buffer).await.unwrap() > 0 {
                tx.send(Ok(BlobData {
                    data: Some(Data::ChunkData(buffer.into())),
                }))
                .await
                .unwrap()
                //.map_err(|e| Status::internal(format!("Unable to send data: {}", e.to_string())))?;
            }

            tx.send(Ok(BlobData {
                data: Some(Data::Info(FileInfo {
                    extension: ".jpeg".to_string(),
                    file_name: file_name,
                    meta_text: "Meta text".to_string(),
                })),
            }))
            .await
            .unwrap()
            //.map_err(|e| Status::internal(format!("Unable to send data: {}", e.to_string())))?;
        });

        Ok(Response::new(rx))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use blob::{blob_handler_client::BlobHandlerClient, BlobData, BlobInfo, FileInfo};
    use dotenv::dotenv;
    use futures::stream::iter;

    pub mod blobtest {
        tonic::include_proto!("blob");
    }

    async fn upload_image(path: &str) -> Result<BlobInfo, Box<dyn std::error::Error>> {
        let mut file = tokio::fs::File::open(path)
            .await
            .expect("File did not exist!!");
        let mut client = BlobHandlerClient::connect("http://0.0.0.0:50051").await?;

        let mut bif = Vec::new();
        file.read_to_end(&mut bif).await.expect("Read did not work");

        let mut arr: Vec<BlobData> = bif
            .chunks(1024)
            .map(|x| BlobData {
                data: Some(Data::ChunkData(x.into())),
            })
            .collect();

        arr.push(BlobData {
            data: Some(Data::Info(FileInfo {
                extension: ".jpeg".to_string(),
                file_name: "".to_string(),
                meta_text: "Smooth".to_string(),
            })),
        });

        let request = tonic::Request::new(iter(arr));
        let res = client.upload(request).await?;

        Ok(res.into_inner())
    }

    async fn download_image(blob_id: &str, output_path: &str) -> String {
        let mut client = BlobHandlerClient::connect("http://0.0.0.0:50051")
            .await
            .unwrap();
        let stream = client
            .download(BlobInfo {
                blob_id: blob_id.to_string(),
            })
            .await
            .unwrap();

        let path = format!("{}/test_{}", output_path, blob_id);
        let mut file_ext: Option<String> = None;
        let mut file = tokio::fs::File::create(&path).await.unwrap();

        let mut s = stream.into_inner();

        while let Some(req) = s.message().await.unwrap() {
            if let Some(d) = req.data {
                match d {
                    Data::Info(info) => file_ext = Some(info.extension),
                    Data::ChunkData(chunk) => {
                        file.write_all(&chunk).await.unwrap();
                    }
                }
            }
        }
        file.sync_all().await.unwrap();

        assert!(file_ext.is_some());
        let new_path = format!("{}{}", &path, &file_ext.unwrap());
        std::fs::rename(&path, &new_path).unwrap();
        new_path
    }

    #[tokio::test(core_threads = 1)]
    async fn upload_download_works() {
        dotenv().ok();
        let file = dotenv::var("TEST_JPEG").unwrap();
        let path = dotenv::var("UPLOAD_PATH").unwrap();

        let upload = upload_image(&file).await.unwrap();
        assert!(!upload.blob_id.is_empty());

        let download = download_image(&upload.blob_id, &path).await;
        assert!(std::fs::read(download).is_ok())
    }
}
