// main article
Article == document - Image - comment[] - likeCount - Text - Tags[] - ...

/// Filtered main article?  
FeedArticle ≠ document - Image - commentCount - likeCount - ...

// #MyHashTag @MyUserName
Cached: Tags + UserNames

Scenario: - New Article is posted -> - A Article document is created <--- mongo - Article is cached <--- Redis ( Second listener (changeStream mongo) ) - A FeedArticle is created <--- mongo ( Second listener (changeStream mongo) ) - ArticleFeed is Cached within Given tags/usernames <--- redis ( Second listener (changeStream mongo) ) - Tell the listening clients a article within Given tags/usernames has been created through - Redis channel OR mongodb FeedArticle change stream
