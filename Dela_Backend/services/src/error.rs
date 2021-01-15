use thiserror::Error;

#[derive(Error, Debug)]
pub enum ServiceError {
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error("I'm sorry! {0}")]
    WeMessedUp(String),
    #[error("unknown data store error")]
    Unknown,
}
