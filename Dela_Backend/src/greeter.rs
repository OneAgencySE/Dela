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
