#[cfg(test)]
mod tests {
    use blob::{
        blob_data::Data, blob_handler_client::BlobHandlerClient, BlobData, BlobInfo, FileInfo,
    };
    use dotenv::dotenv;
    use futures::stream::iter;
    use services::BlobService;

    pub mod blob {
        tonic::include_proto!("blob");
    }

    struct TestBlobClient {
        client: BlobHandlerClient<tonic::transport::Channel>,
        blob_service: BlobService,
        files_path: String,
    }

    impl TestBlobClient {
        async fn new(dst: String, files_path: String) -> Self {
            let client = BlobHandlerClient::connect(dst).await.unwrap();
            let blob_service = BlobService::new(files_path.clone());
            TestBlobClient {
                client,
                blob_service,
                files_path,
            }
        }

        async fn upload_image(
            &mut self,
            test_file: &str,
        ) -> Result<BlobInfo, Box<dyn std::error::Error>> {
            // Copy a file so we know it exists
            tokio::fs::copy(&test_file, format!("{}/{}", self.files_path, &test_file))
                .await
                .unwrap();

            let mut reader = self.blob_service.reader(&test_file).await;
            let mut arr = Vec::new();

            while let Some(chunk) = reader.read().await {
                arr.push(BlobData {
                    data: Some(Data::ChunkData(chunk)),
                });
            }

            arr.push(BlobData {
                data: Some(Data::Info(FileInfo {
                    extension: ".jpeg".to_string(),
                    file_name: "".to_string(),
                    meta_text: "Smooth".to_string(),
                })),
            });

            let res = self.client.upload(tonic::Request::new(iter(arr))).await?;

            Ok(res.into_inner())
        }

        async fn download_image(&mut self, blob_id: &str) -> (String, Option<FileInfo>) {
            let stream = self
                .client
                .download(BlobInfo {
                    blob_id: blob_id.to_string(),
                })
                .await
                .unwrap();

            let mut stream = stream.into_inner();
            let mut blob = self.blob_service.writer().create_blob().await;
            let mut file_info: Option<FileInfo> = None;

            while let Some(req) = stream.message().await.unwrap() {
                if let Some(d) = req.data {
                    match d {
                        Data::Info(info) => file_info = Some(info),
                        Data::ChunkData(chunk) => blob.append(chunk).await,
                    }
                }
            }
            (blob.finalize(".test.jpeg").await, file_info)
        }
    }

    #[tokio::test(core_threads = 1)]
    async fn upload_download_works() {
        dotenv().ok();
        let file = "test_img.jpeg";
        let path = dotenv::var("UPLOAD_PATH").unwrap();
        let mut test_client =
            TestBlobClient::new("http://0.0.0.0:50051".to_string(), path.clone()).await;

        let upload = test_client.upload_image(&file).await.unwrap();
        assert!(!upload.blob_id.is_empty());

        let (file_id, info) = test_client.download_image(&upload.blob_id).await;
        assert!(info.is_some());
        assert!(std::fs::read(format!("{}/{}", path, file_id)).is_ok());
    }
}
