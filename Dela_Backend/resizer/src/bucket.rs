use std::fmt::Display;
use crate::providers::Quality;

/// Representation of available buckets. 
/// Use to_string() to access the correct string representation.
pub enum Bucket {
    OriginalImage,
    WebImage,
    PhoneImage,
    Thumbnail
}

impl Display for Bucket {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {

        let  name = match self {
            Bucket::OriginalImage => "user_orig_img",
            Bucket::WebImage => "user_web_img",
            Bucket::PhoneImage => "user_phone_img",
            Bucket::Thumbnail => "user_thumbnail_img"
        };

        write!(f, "{}",name)
    }
}

impl Bucket {
    /// Use Proto enum type Quality to define 
    /// the name of the bucket, defaults to phone bucket
    pub fn from_img_quality<'a>(info: i32) -> Bucket {
        match info {
            x if x == Quality::Original as i32 => Bucket::OriginalImage,
            x if x == Quality::Web as i32 => Bucket::WebImage,
            x if x == Quality::Thumbnail as i32 => Bucket::Thumbnail,
            _ => Bucket::PhoneImage,
        }
    }
}