fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure().compile(&["helloworld.proto", "blob.proto"], &["../Proto"])?;
    Ok(())
}
