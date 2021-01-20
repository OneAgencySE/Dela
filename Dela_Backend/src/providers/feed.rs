use async_stream::{stream, try_stream};
use futures::{Stream, StreamExt};
use services::{BlobService, ServiceError};
use std::pin::Pin;
use tonic::{Request, Response, Status, Streaming};
use tracing::{error, info};

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
    pub fn new(settings: &Settings) -> Result<Self, ServiceError> {
        Ok(FeedProvider {
            blob_service: BlobService::new(settings.upload_path.clone())?,
        })
    }
}

#[tonic::async_trait]
impl FeedHandler for FeedProvider {
    type SubscribeStream =
        Pin<Box<dyn Stream<Item = Result<SubResponse, Status>> + Send + Sync + 'static>>;

    #[tracing::instrument]
    async fn subscribe(
        &self,
        request: Request<Streaming<SubRequest>>,
    ) -> Result<Response<Self::SubscribeStream>, Status> {
        info!("Setting up stream");
        let mut stream = request.into_inner();

        // TODO: get rid of this dependency, alt use ARC
        let service = self.blob_service.clone();

        let output = try_stream! {
            while let Some(req) = stream.next().await {
                if let Some(state) = req?.state {

                    let feed_stream = stream_test(state, service.clone());
                    futures_util::pin_mut!(feed_stream); // needed for yield iterations to "lock" memory location

                    for await value in feed_stream {
                        yield value
                    }
                }
            }
            info!("Stream disconnected");
        };

        Ok(Response::new(Box::pin(output) as Self::SubscribeStream))
    }
}

// TODO: Break out to it's own service and get rid of the fs:: dependency
fn stream_test(state: State, service: BlobService) -> impl Stream<Item = SubResponse> {
    stream! {
            let mut seen = Box::pin(Vec::new());
            match state {
                State::Fetch(count) => {
                    let files: Vec<String> = std::fs::read_dir("Upload")
                    .unwrap()
                    .map(|x| x.unwrap().file_name().into_string().unwrap())
                    .filter(|x| x.ends_with(".jpeg") && !seen.contains(x))
                    .take(count as usize)
                    .collect();

                    println!("Count: {}", count);
                    for file in files {
                        if let Ok(mut reader) = service.reader(&file).await {
                            yield SubResponse {
                                value: Some(Value::Info(FeedArticle {
                                article_id: file.clone(),
                                comments: 0,
                                likes: 5,
                            })),
                        };

                        while let Some(chunk) = reader.read().await.unwrap_or_else(|err| {
                            error!("Service Error: {}", err);
                            None
                        }) {
                            yield SubResponse {
                                value: Some(Value::Image(FeedImage {
                                    chunk_data: chunk,
                                    article_id: file.clone(),
                                    is_done: false,

                                })),
                            };
                        }

                        yield SubResponse {
                            value: Some(Value::Image(FeedImage {
                                chunk_data: Vec::new(),
                                article_id: file.clone(),
                                is_done: true,
                            })),
                        };
                    }
                    info!("Done sending file! {}", &file);
                }
            }
            State::WatchedArticleId(s) => {
                info!("Adding to watched: {}", &s);
                seen.push(s)
            }
        };
    }
}
