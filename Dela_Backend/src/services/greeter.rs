pub use helloworld::greeter_server::GreeterServer;
use helloworld::{greeter_server::Greeter, HelloReply, HelloRequest};
use tonic::{Request, Response, Status};

pub mod helloworld {
    tonic::include_proto!("helloworld");
}

#[derive(Debug, Default)]
pub struct MyGreeter {}

#[tonic::async_trait]
impl Greeter for MyGreeter {
    async fn say_hello(&self, req: Request<HelloRequest>) -> Result<Response<HelloReply>, Status> {
        println!("Got a messenger from the client: {:?}", &req);

        let reply = HelloReply {
            message: format!("Hello {}!", req.into_inner().name).into(),
        };

        Ok(Response::new(reply))
    }
}

#[cfg(test)]
mod tests {
    use helloworld::{greeter_client::GreeterClient, HelloReply, HelloRequest};

    pub mod helloworld {
        tonic::include_proto!("helloworld");
    }

    async fn call_hello_world(msg: &str) -> Result<HelloReply, Box<dyn std::error::Error>> {
        let mut client = GreeterClient::connect("http://0.0.0.0:50051").await?;

        let request = tonic::Request::new(HelloRequest { name: msg.into() });

        Ok(client.say_hello(request).await?.into_inner())
    }

    #[tokio::test(core_threads = 1)]
    async fn greet() {
        let res = call_hello_world("Smooth").await.unwrap();
        assert_eq!(res.message, "Hello Smooth!");
    }
}
