use tokio::{fs::File, io::AsyncReadExt, io::AsyncWriteExt, sync::mpsc};
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
pub struct FeedService {}

#[tonic::async_trait]
impl FeedHandler for FeedService {
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
                        State::WatchedArticleId(x) => unimplemented!(),
                        State::Count(x) => unimplemented!(),
                    };
                }
            }
            info!("Stream disconnected")
        });

        Ok(Response::new(rx))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use feed::{
        feed_handler_client::FeedHandlerClient, feed_handler_server::FeedHandler,
        sub_request::State, sub_response::Value, FeedArticle, SubRequest, SubResponse,
    };
    #[tokio::test(core_threads = 3)]
    async fn subscribe() {
        let mut client = FeedHandlerClient::connect("http://0.0.0.0:50051")
            .await
            .unwrap();
        let (mut tx, rx) = mpsc::channel(5);

        let mut stream = client
            .subscribe(Request::new(rx))
            .await
            .unwrap()
            .into_inner();

        tx.send(SubRequest {
            state: Some(State::StartFresh(true)),
        })
        .await
        .unwrap();

        while let Some(r) = stream.message().await.unwrap() {
            match r.value.unwrap() {
                Value::Info(i) => println!("Received article: {}", i.article_id),
                Value::Image(_) => break,
            };
            tokio::time::delay_for(tokio::time::Duration::from_secs(1)).await;
            tx.send(SubRequest {
                state: Some(State::StartFresh(false)),
            })
            .await
            .unwrap();
        }
    }
}
