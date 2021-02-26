use bytes::Bytes;
use futures::Stream;
use rusoto_core::{ByteStream, Region};
use rusoto_s3::{GetObjectRequest, PutObjectRequest, S3, S3Client};
use crate::{Settings,bucket::Bucket};
use anyhow::{Result,anyhow};

pub struct S3Storage {
    client: S3Client
}

impl S3Storage {
    pub fn new(config: &Settings) -> Self {
        let region = Region::Custom{
            name: config.s3_region.to_owned(),
            endpoint: config.s3_endpoint.to_owned(),
        };
        S3Storage {
            client: S3Client::new(region)
        }
    }

    pub async fn download(&self, bucket: Bucket, file_id: String) -> Result<impl Stream<Item = Result<Bytes, std::io::Error>>> {
        let request = GetObjectRequest{
            bucket: bucket.to_string(),
            key: file_id,
            ..Default::default()
        };
        let res = self.client.get_object(request).await?;

        if let Some(bs) = res.body {
            Ok(bs)
        } else {
            // TODO: Tracing?
            Err(anyhow!("Could not initiate stream, check tracing records"))
        }
    }

    pub async fn upload<T>(&self, bucket: Bucket, file_id: &String, stream: T) -> Result<()> 
        where T: Stream<Item = Result<Bytes, std::io::Error>> + Send + Sync + 'static {

        let request = PutObjectRequest {
            bucket: bucket.to_string(),
            key: file_id.clone(),
            body: Some(ByteStream::new(stream)),
            ..Default::default()
        };
        
        self.client.put_object(request).await?;
        Ok(())
    }
}