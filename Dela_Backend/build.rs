fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure().compile(&["blob.proto", "feed.proto"], &["../Proto"])?;
    Ok(())
}
