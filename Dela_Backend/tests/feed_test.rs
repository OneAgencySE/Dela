#[cfg(test)]
mod tests {
    use tokio::sync::mpsc;
    use tonic::Request;

    pub mod feed {
        tonic::include_proto!("feed");
    }

    use feed::{
        feed_handler_client::FeedHandlerClient, sub_request::State, sub_response::Value, SubRequest,
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

        let mut count = 0;
        while let Some(r) = stream.message().await.unwrap() {
            match r.value.unwrap() {
                Value::Info(i) => println!("Received article: {}", i.article_id),
                Value::Image(image) => {
                    if image.is_done {
                        count += 1;
                        println!("Done!!");
                    }

                    if count == 5 {
                        break;
                    }
                }
            };
        }
    }
}
