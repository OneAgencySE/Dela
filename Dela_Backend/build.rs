fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure().compile(&["blob.proto", "feed.proto"], &["../Proto"])?;
    tonic_build::configure().build_server(false).compile(&["imagehandler.proto"], &["./proto_internal"])?;
    Ok(())
}
