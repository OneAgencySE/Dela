
#[derive(Debug)]
pub struct FeedService {
    
}

impl FeedService {

    /// This method will 
    pub async fn seen(user_id: &str, article_id: &str) {
        // TODO: add to user specific cache
        // Should be picked up by second service to update the database by Queue subscriber in redis
    }
}


