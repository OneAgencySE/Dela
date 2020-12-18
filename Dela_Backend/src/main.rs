mod greeter;

use greeter::{GreeterServer, MyGreeter};
use tonic::transport::Server;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr = "[::1]:50051".parse()?;
    let greeter = MyGreeter::default();

    Server::builder()
        .add_service(GreeterServer::new(greeter))
        .serve(addr)
        .await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use helloworld::{greeter_client::GreeterClient, HelloReply, HelloRequest};

    pub mod helloworld {
        tonic::include_proto!("helloworld");
    }

    async fn call_hello_world(msg: &str) -> Result<HelloReply, Box<dyn std::error::Error>> {
        let mut client = GreeterClient::connect("http://[::1]:50051").await?;

        let request = tonic::Request::new(HelloRequest { name: msg.into() });

        Ok(client.say_hello(request).await?.into_inner())
    }

    #[tokio::test(core_threads = 1)]
    async fn test_name() {
        let res = call_hello_world("Smooth").await.unwrap();
        assert_eq!(res.message, "Hello Smooth!");
    }
}
