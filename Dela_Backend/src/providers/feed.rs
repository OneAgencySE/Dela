use std::vec;

use services::BlobService;
use tokio::sync::mpsc;
use tonic::{Request, Response, Status, Streaming};
use tracing::info;

pub mod feed {
    tonic::include_proto!("feed");
}
pub use feed::feed_handler_server::FeedHandlerServer;
use feed::{
    feed_handler_server::FeedHandler, sub_request::State, sub_response::Value, FeedArticle,
    FeedImage, SubRequest, SubResponse,
};

use crate::Settings;

#[derive(Debug)]
pub struct FeedProvider {
    blob_service: BlobService,
}

impl FeedProvider {
    pub fn new(settings: &Settings) -> Self {
        FeedProvider {
            blob_service: BlobService::new(settings.upload_path.clone()),
        }
    }
}

#[tonic::async_trait]
impl FeedHandler for FeedProvider {
    type SubscribeStream = mpsc::Receiver<Result<SubResponse, Status>>;

    async fn subscribe(
        &self,
        request: Request<Streaming<SubRequest>>,
    ) -> Result<Response<Self::SubscribeStream>, tonic::Status> {
        info!("Setting up stream");
        let meta = &request.metadata();
        let user_id: String = meta
            .get_all("x-user")
            .iter()
            .map(|c| c.to_str().unwrap().to_string())
            .take(1)
            .collect();

        let mut stream = request.into_inner();
        let (mut tx, rx) = mpsc::channel(5);
        let service = self.blob_service.clone();

        tokio::spawn(async move {
            let mut seen = Vec::new();
            let mut count = 5;
            while let Some(req) = stream.message().await.unwrap_or_default() {
                if let Some(state) = req.state {
                    match state {
                        State::StartFresh(_x) => {
                            let files: Vec<String> = std::fs::read_dir("Upload")
                                .unwrap()
                                .map(|x| x.unwrap().file_name().into_string().unwrap())
                                .filter(|x| x.ends_with(".jpeg") && !seen.contains(x))
                                .take(count)
                                .collect();

                            for file in files {
                                tx.send(Ok(SubResponse {
                                    value: Some(Value::Info(FeedArticle {
                                        article_id: file.clone(),
                                        comments: 0,
                                        likes: 5,
                                    })),
                                }))
                                .await
                                .unwrap();

                                let mut reader = service.reader(&file).await;
                                while let Some(chunk) = reader.read().await {
                                    tx.send(Ok(SubResponse {
                                        value: Some(Value::Image(FeedImage {
                                            chunk_data: chunk,
                                            is_done: false,
                                        })),
                                    }))
                                    .await
                                    .unwrap();
                                }

                                tx.send(Ok(SubResponse {
                                    value: Some(Value::Image(FeedImage {
                                        chunk_data: Vec::new(),
                                        is_done: true,
                                    })),
                                }))
                                .await
                                .unwrap();

                                seen.push(file.clone());
                                info!("Done sending file! {}", &file)
                            }
                        }
                        State::WatchedArticleId(s) => info!("Watched! {}", s), // seen.push(s),
                        State::Count(c) => count = c as usize,
                    };
                }
            }
            info!("Stream disconnected")
        });

        Ok(Response::new(rx))
    }
}
