
use image::{GenericImageView, imageops::FilterType};
use std::io::Result;
use crate::{blob::Blob, providers::Quality};

const MAX_ORIGINAL_SIZE: (u32, u32) = (3840,2160);
const MAX_WEB_SIZE: (u32, u32) = (2400,1600);
const MAX_PHONE_SIZE: (u32, u32) = (1300, 3000);
const MAX_THUMBNAIL_SIZE: (u32, u32) = (1300, 3000);

pub struct ImageResizer;

impl ImageResizer {
    pub async fn resize(main_blob: &mut Blob, quality: Quality) -> Result<Blob> {
        let main_img = image::load_from_memory(main_blob.read_all().await?.as_slice()).unwrap();
        let dimensions = main_img.dimensions();
        let max: (u32,u32) = quality.into();

        let width_ratio = max.0 / dimensions.0;
        let height_ratio = max.1 / dimensions.1;
        
        let new_dimentions = if width_ratio > height_ratio {
            (dimensions.0 * height_ratio, dimensions.1 * height_ratio) 
        } else {
            (dimensions.0 * width_ratio, dimensions.1 * width_ratio) 
        };
        let resized = main_img.resize(new_dimentions.0, new_dimentions.1, FilterType::Nearest);
        
        let mut new_img = Blob::new().await?;
        new_img.append(resized.as_bytes()).await?; // TODO: Make sure images are stored as PNG
        new_img.finalize(".png").await?;
        
        Ok(new_img)
    }
}

impl Into<(u32,u32)> for Quality {
    fn into(self) -> (u32,u32) {
        use Quality::*;
        match self {
            Phone => MAX_PHONE_SIZE,
            Web => MAX_WEB_SIZE, 
            Original => MAX_ORIGINAL_SIZE,
            Thumbnail => MAX_THUMBNAIL_SIZE
        }
    }
}