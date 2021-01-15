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

#[derive(Debug, Default)]
pub struct FeedProvider {}

#[tonic::async_trait]
impl FeedHandler for FeedProvider {
    type SubscribeStream = mpsc::Receiver<Result<SubResponse, Status>>;

    async fn subscribe(
        &self,
        request: Request<Streaming<SubRequest>>,
    ) -> Result<Response<Self::SubscribeStream>, tonic::Status> {
        info!("Setting up stream");
        let mut stream = request.into_inner();
        let (mut tx, rx) = mpsc::channel(5);
        tokio::spawn(async move {
            while let Some(req) = stream.message().await.unwrap_or_default() {
                if let Some(state) = req.state {
                    match state {
                        State::StartFresh(x) => {
                            if x {
                                tx.send(Ok(SubResponse {
                                    value: Some(Value::Info(FeedArticle {
                                        article_id: "foo".to_string(),
                                        likes: 42,
                                        comments: 3,
                                    })),
                                }))
                                .await
                                .unwrap();
                            } else {
                                tx.send(Ok(SubResponse {
                                    value: Some(Value::Image(FeedImage {
                                        is_done: true,
                                        chunk_data: vec![],
                                    })),
                                }))
                                .await
                                .unwrap();
                            }
                        }
                        State::WatchedArticleId(_x) => unimplemented!(),
                        State::Count(_x) => unimplemented!(),
                    };
                }
            }
            info!("Stream disconnected")
        });

        Ok(Response::new(rx))
    }
}
