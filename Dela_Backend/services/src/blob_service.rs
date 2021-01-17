use tokio::{
    fs::File,
    io::{AsyncReadExt, AsyncWriteExt, BufStream},
};
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct BlobService {
    blob_dir: String,
}

pub struct BlobWriter<'a> {
    blob_dir: &'a str,
}

pub struct Blob<'a> {
    file: File,
    blob_dir: &'a str,
    blob_id: String,
}

pub struct BlobStreamReader {
    buffer: [u8; 1024],
    stream: BufStream<File>,
}

impl BlobService {
    pub fn new(file_path: String) -> Self {
        let service = BlobService {
            blob_dir: file_path,
        };
        service.validate_path();
        service
    }

    fn validate_path(&self) {
        std::fs::read_dir(&self.blob_dir).unwrap();
    }

    /// Creates a blob writer that will write a blob to disk
    pub fn writer(&self) -> BlobWriter {
        BlobWriter::new(&self.blob_dir)
    }

    /// Returns a blob reader
    /// It can be used to buffer the file
    pub async fn reader(&self, blob_id: &str) -> BlobStreamReader {
        let path = format!("{}/{}", &self.blob_dir, blob_id);
        let file = tokio::fs::File::open(path).await.unwrap();
        BlobStreamReader::new(file)
    }
}

impl<'a> BlobWriter<'a> {
    pub(crate) fn new(file_path: &'a str) -> Self {
        BlobWriter {
            blob_dir: file_path,
        }
    }

    /// Creates a blob reference with an actual file reference
    pub async fn create_blob(&self) -> Blob<'a> {
        let blob_id = Uuid::new_v4().to_string();
        let path = format!("{}/{}", &self.blob_dir, &blob_id);
        let file = File::create(&path).await.unwrap();
        Blob {
            file,
            blob_dir: self.blob_dir,
            blob_id,
        }
    }
}

impl Blob<'_> {
    /// Write bytes to file
    pub async fn append(&mut self, chunk: Vec<u8>) {
        self.file.write_all(&chunk).await.unwrap();
    }

    /// Write the blob to disk and set the correct file extension
    /// returns the final name with the supplied extension
    pub async fn finalize(mut self, extension: &str) -> String {
        self.file.sync_all().await.unwrap();
        let path = format!("{}/{}", &self.blob_dir, &self.blob_id);
        tokio::fs::rename(&path, format!("{}{}", &path, &extension))
            .await
            .unwrap();
        // Return with the extension
        format!("{}{}", &self.blob_id, &extension)
    }

    /// Delete the blob and clean up
    pub async fn abort(self) {
        let path = format!("{}/{}", &self.blob_dir, &self.blob_id);
        tokio::fs::remove_file(&path).await.unwrap();
    }

    /// Get a blob reader, this will consume the blob and return the reader
    pub fn into_stream_reader(self) -> BlobStreamReader {
        BlobStreamReader::new(self.file)
    }
}

impl BlobStreamReader {
    pub(crate) fn new(file: File) -> Self {
        BlobStreamReader {
            buffer: [0u8; 1024],
            stream: BufStream::new(file),
        }
    }

    /// Returns a chunk of the file
    /// each call will iterate one step further until
    /// the whole file is read
    /// ```
    ///  let service = BlobService::new("/my_folder".to_string());
    ///  let reader = service.reader("my_file.jpeg").await;
    ///  while let Some(chunk) = reader.read().await {
    ///         assert!(chunk.len() > 0)
    ///  }
    /// ```
    pub async fn read(&mut self) -> Option<Vec<u8>> {
        let res = self.stream.read(&mut self.buffer).await.unwrap();

        if res > 0 {
            Some(self.buffer.into())
        } else {
            None
        }
    }
}
