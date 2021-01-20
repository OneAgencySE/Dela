#[cfg(test)]
mod tests {
    use async_stream::stream;
    use tonic::Request;

    pub mod feed {
        tonic::include_proto!("feed");
    }

    use feed::{
        feed_handler_client::FeedHandlerClient, sub_request::State, sub_response::Value, SubRequest,
    };

    #[tokio::test]
    async fn subscribe() {
        let mut client = FeedHandlerClient::connect("http://0.0.0.0:50051")
            .await
            .unwrap();

        let outbound_stream = stream! {
            yield SubRequest {
                state: Some(State::Fetch(5)),
            };
        };

        let mut inbound_stream = client
            .subscribe(Request::new(outbound_stream))
            .await
            .unwrap()
            .into_inner();
        let mut count = 0;
        while let Some(r) = inbound_stream.message().await.unwrap() {
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
