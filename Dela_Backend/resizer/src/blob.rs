use std::{io::{BufReader, Read}, path::Path, task::Poll};
use bytes::{Bytes, BytesMut};
use futures::Stream;
use tokio::fs::{self, File};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

pub const TEMP_DIR: &'static str = "temp";

pub struct Blob {
    file: File,
    path: String
}

impl Blob {
    pub async fn new() -> std::io::Result<Self> {
        let name = uuid::Uuid::new_v4().to_string();
        let path = format!("{}/{}", TEMP_DIR, name);
        let file = File::create(Path::new(&path)).await?;
        Ok(Blob { file, path })
    }

    /// Write bytes to file
    pub async fn append(&mut self, chunk: &[u8]) -> std::io::Result<()> {
        self.file.write_all(&chunk).await?;
        Ok(())
    }

    pub async fn read_all(&mut self) -> std::io::Result<Vec<u8>> {
        let mut buf = Vec::new();
        self.file.read_to_end(&mut buf).await?;
        Ok(buf)
    }

    /// Write final bytes and add extension to file
    pub async fn finalize(&mut self, extension: &str) -> std::io::Result<()> {
        self.file.sync_all().await?;
        let new_path = format!("{}{}", self.path,extension);
        let new_path = Path::new(&new_path);
        let res = fs::rename(Path::new(&self.path), new_path).await;
        self.file = fs::File::open(new_path).await?; // TODO: Check if rename breaks connection or not
        self.path.push_str(extension);
        res
    }

    pub fn into_stream(self) -> BlobStreamReader {
        BlobStreamReader::new(std::fs::File::open(Path::new(&self.path)).expect("File should exists"))
    }
}

impl Drop for Blob {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(&self.path);
    }
}

    pub struct BlobStreamReader {
        buffer: Vec<u8>,
        reader: BufReader<std::fs::File>,
    }

impl BlobStreamReader {
    pub(crate) fn new(file: std::fs::File) -> Self {
        BlobStreamReader {
            buffer: Vec::with_capacity(1024),
            reader: BufReader::new(file)
        }
    }

    pub fn read(&mut self) -> Option<Vec<u8>> {
        if let Ok(v) = self.reader.read(&mut self.buffer) {
            if v < 1 {
                None
            } else {
                Some(self.buffer.clone())
            }
        } else {
            None
        }
    }


    // pub async fn read<E>(&mut self) -> Result<Option<Vec<u8>>, String>{
    //     let res: usize = self.stream.read(&mut self.buffer).await.map_err(|e| e.to_string())?;

    //     Ok(if res > 0 {
    //         Some(self.buffer.into())
    //     } else {
    //         None
    //     })
    // }

}

impl Stream for BlobStreamReader {
    type Item = std::io::Result<Bytes>;

    fn poll_next(
        mut self: std::pin::Pin<&mut Self>,
        _: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Option<Self::Item>> {
        if let Some(x) = (*self).read() {
            Poll::Ready(Some(Ok(
                BytesMut::from(&x[..]).into()
            )))
        } else {
            Poll::Ready(None)
        }
    }
}