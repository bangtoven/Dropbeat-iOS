//
//  NetworkPath.swift
//  labs

import Foundation

let RELEASE = false

extension ApiPath {
    static let hostV2 = RELEASE ? "http://dropbeat.net/api/v2/" : "http://spark.coroutine.io/api/v2/"

    static let streamFollowing = hostV2 + "stream/following/"
}

public class ApiPath {
    static let host = RELEASE ? "http://dropbeat.net/api/v1/" : "http://spark.coroutine.io/api/v1/"
    
    // User
    static let user = host + "user/"
    static let userSignIn = user + "signin_fb_android/"
    static let userSelf = user + "self/"
    static let userSignOut = user + "signout/"
    static let userUnlock = user + "unlock/"
    static let userChangeEmail = user + "change_email/"
    static let userEmailSignup = user + "email_signup/"
    static let userEmailSignin = user + "email_signin/"
    static let userChangeNickname = user + "change_nickname/"
    static let userChangeAboutMe = user + "change_desc/"
    static let userLikeList = user + "like/"
    static let userFollowers = user + "followers/"
    static let userFollowing = user + "following/"
    
    static let resolveUser = host + "resolve/"
    static let followUser = user + "follow/"
    static let unfollowUser = user + "unfollow/"
    
    // Feed
    static let feed = host + "feed/"
    static let feedChannel = feed + "channel/"
    static let feedFriend = feed + "friend/"
    
    // Playlist
    static let playlist = host + "playlist/"
    static let playlistList = playlist + "list/"
    static let playlistSet = playlist + "set/"
    static let playlistIntial = playlist + "initial/"
    static let playlistShared = playlist + "shared/"
    static let playlistImport = playlist + "import/"
    static let playlistDel = playlist + "del/"
    
    // Log
    static let log = host + "log/"
    static let logSearch = log + "search/"
    static let logResolve = log + "resolve/"
    static let logTrackAdd = log + "trackadd/"
    static let logPlay = log + "play/"
    static let logPlayDrop = log + "playdrop/"
    static let logPlaybackDetail = log + "playback_detail/"
    static let logPlayFailure = log + "playfailure/"
    static let logDebug = log + "debug/"
    
    // Meta
    static let meta = host + "meta/"
    static let metaVersion = meta + "version/"
    static let metaKey = meta + "key/"
    
    // Bookmark
    static let bookmark = host + "channelbookmark/"
    
    // Genre
    static let genre = host + "genre/"
    static let genreFavorite = genre + "favorite/"
    static let genreAddFavorite = genre + "add_favorite/"
    static let genreDelFavorite = genre + "del_favorite/"
    
    // Track
    static let track = host + "track/"
    static let trackShare = track + "shared/"
    static let trackLike = track + "like/"
    static let trackDislike = track + "dislike/"
    
    static let userTrack = host + "usertrack/"
    static let userTrackNewUploads = userTrack + "newest/"
    static let userTrackLike = userTrack + "like/"
    
    // Artist
    static let artist = host + "artist/"
    static let artistFollow = artist + "follow/"
    static let artistUnfollow = artist + "unfollow/"
    
    // Feedback
    static let feedback = host + "async/feedback/"
    
}

public class CorePath {
    static let host = RELEASE ? "http://core.dropbeat.net/api/" : "http://core.coroutine.io/api/"
    
    // core.search
    static let newSearch = host + "v1/search/"
    
    static let search = host + "search/"
    static let searchRelated = search + "related/"
    static let searchLiveset = search + "liveset/"
    static let searchOther = search + "other/"
    static let searchArtist = search + "artist/"
    
    // core.resolve
    static let resolve = host + "resolve/"
    
    // core.related
    static let related = host + "related/"
    
    // core.live
    static let live = host + "live/"
    static let liveTracklist = live + "tracklist/"

    // core.trending
    static let trending = host + "trending/"
    static let trendingChart = trending + "bpchart/"
    static let trendingFeaturedPlaylist = trending + "featured_playlist/"
    
    // core.podcast
    static let podcast = host + "podcast/"
    
    // core.event
    static let event = host + "event/"
    
    // core.channel
    static let channel = host + "channel/"
    static let channelList = channel + "list/"
    static let channelDetail = channel + "detail/"
    static let channelDescExtractUrl = channel + "extract/"
    // core.channel playlist
    static let channelGproxy = channel + "gproxy/"
    static let channelFeed = channel + "feed/"

    // core.artistFilter
    static let artistFilter = host + "artist/filter/"
    
    // core.genre
    static let genre = host + "genre/"
    static let genreSample = host + "genre/sample_tracks/"
    
    // core.stream
    static let stream = host + "stream/"
    static let streamNew = stream + "new/"
    static let streamTrending = stream + "trending/"
    
}

public class YoutubeApiPath {
    static let host = "https://www.googleapis.com/youtube/v3/"
    static let playlistItems = host + "playlistItems/"
}
