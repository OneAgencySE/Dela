#[cfg(test)]
mod tests {
    use blob::{
        blob_data::Data, blob_handler_client::BlobHandlerClient, BlobData, BlobInfo, FileInfo,
    };
    use dotenv::dotenv;
    use futures::stream::iter;
    use tokio::{io::AsyncReadExt, io::AsyncWriteExt};

    pub mod blob {
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

        let path = format!("{}/test_down_{}", output_path, blob_id);
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
        let file = "test_img.jpeg";
        let path = dotenv::var("UPLOAD_PATH").unwrap();

        let upload = upload_image(&file).await.unwrap();
        assert!(!upload.blob_id.is_empty());

        let download = download_image(&upload.blob_id, &path).await;
        assert!(std::fs::read(download).is_ok())
    }
}
