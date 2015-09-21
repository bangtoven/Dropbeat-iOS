//
//  NetworkPath.swift
//  labs

import Foundation

let RELEASE = false

public class ApiPath {
    static var host :String = RELEASE ? "http://dropbeat.net/api/v1/" : "http://spark.coroutine.io/api/v1/"
    
    // User
    static var user :String = host + "user/"
    static var userSignIn :String = user + "signin_fb_android/"
    static var userSelf :String = user + "self/"
    static var userSignOut :String = user + "signout/"
    static var userUnlock :String = user + "unlock/"
    static var userChangeEmail :String = user + "change_email/"
    static var userEmailSignup:String = user + "email_signup/"
    static var userEmailSignin:String = user + "email_signin/"
    static var userChangeNickname:String = user + "change_nickname/"
    static var userLikeList:String = user + "like/"
    static var userFollowers:String = user + "followers/"
    static var userFollowing:String = user + "following/"
    
    // Feed
    static var feed :String = host + "feed/"
    static var feedChannel :String = feed + "channel/"
    static var feedFriend :String = feed + "friend/"
    
    // Playlist
    static var playlist :String = host + "playlist/"
    static var playlistAll :String = playlist + "all/"
    static var playlistSet :String = playlist + "set/"
    static var playlistIntial :String = playlist + "initial/"
    static var playlistShared :String = playlist + "shared/"
    static var playlistImport :String = playlist + "import/"
    static var playlistDel :String = playlist + "del/"
    
    // Log
    static var log :String = host + "log/"
    static var logSearch :String = log + "search/"
    static var logResolve :String = log + "resolve/"
    static var logTrackAdd :String = log + "trackadd/"
    static var logPlay :String = log + "play/"
    static var logPlayDrop :String = log + "playdrop/"
    static var logDebug :String = log + "debug/"
    
    // Meta
    static var meta :String = host + "meta/"
    static var metaVersion :String = meta + "version/"
    
    // Bookmark
    static var bookmark :String = host + "channelbookmark/"
    
    // Genre
    static var genre:String = host + "genre/"
    static var genreFavorite:String = genre + "favorite/"
    static var genreAddFavorite:String = genre + "add_favorite/"
    static var genreDelFavorite:String = genre + "del_favorite/"
    
    // Track
    static var track :String = host + "track/"
    static var trackShare :String = track + "shared/"
    static var trackLike:String = track + "like/"
    static var trackDislike:String = track + "dislike/"
    
    // Artist
    static var artist :String = host + "artist/"
    static var artistFollow :String = artist + "follow/"
    static var artistUnfollow :String = artist + "unfollow/"
    static var artistFollowing :String = artist + "following/"
    
    // Stream
    static var stream :String = host + "stream/"
    static var streamFollowing: String = stream + "following/"
    
    // Feedback
    static var feedback :String = host + "async/feedback/"
    
}

public class CorePath {
    static var host :String = RELEASE ? "http://core.dropbeat.net/api/" : "http://core.coroutine.io/api/"
    
    // core.search
    static var search :String = host + "search/"
    static var searchRelated :String = search + "related/"
    static var searchLiveset :String = search + "liveset/"
    static var searchOther :String = search + "other/"
    static var searchArtist: String = search + "artist/"
    
    // core.resolve
    static var resolve :String = host + "resolve/"
    
    // core.related
    static var related :String = host + "related/"
    
    // core.live
    static var live :String = host + "live/"
    static var liveTracklist :String = live + "tracklist/"

    // core.trending
    static var trending :String = host + "trending/"
    static var trendingChart :String = trending + "bpchart/"
    static var trendingFeaturedPlaylist :String = trending + "featured_playlist/"
    
    // core.podcast
    static var podcast :String = host + "podcast/"
    
    // core.event
    static var event :String = host + "event/"
    
    // core.channel
    static var channel :String = host + "channel/"
    static var channelList: String = channel + "list/"
    static var channelDetail: String = channel + "detail/"
    static var channelDescExtractUrl: String = channel + "extract/"
    // core.channel playlist
    static var channelGproxy: String = channel + "gproxy/"
    
    // core.artistFilter
    static var artistFilter: String = host + "artist/filter/"
    
    // core.genre
    static var genre: String = host + "genre/"
    static var genreSample: String = host + "genre/sample_tracks/"
    
    // core.stream
    static var stream: String = host + "stream/"
    static var streamNew: String = stream + "new/"
    static var streamTrending: String = stream + "trending/"
    
}

public class ResolvePath {
    static var host :String = "http://resolve.dropbeat.net/"
    static var resolveStream :String = host + "resolve/"
    
    static var resolveUser: String = "http://spark.coroutine.io/api/v1/resolve/?url=spark.coroutine.io/r/"
}

public class YoutubeApiPath {
    static var host :String = "https://www.googleapis.com/youtube/v3/"
    static var playlistItems :String = host + "playlistItems/"
}