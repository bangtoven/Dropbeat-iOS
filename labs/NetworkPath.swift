//
//  NetworkPath.swift
//  labs

import Foundation

enum HostType {
    case Dropbeat
    case Coroutine
    case Monocheese
}
let hostType: HostType = .Dropbeat

extension ApiPath {
    static let hostV2 = host + "v2/"

    static let streamFollowing = hostV2 + "stream/following/"
}

public class ApiPath {
    static var host: String {
        switch hostType {
        case .Dropbeat:
            return "http://dropbeat.net/api/"
        case .Coroutine:
            return "http://spark.coroutine.io/api/"
        case .Monocheese:
            return "http://monocheese.iptime.org:19030/api/"
        }
    }
    static let hostV1 = host + "v1/"
    
    // Resolve
    static let resolveResource = hostV1 + "resolve/"

    // User
    static let user = hostV1 + "user/"
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
    
    static let followUser = user + "follow/"
    static let unfollowUser = user + "unfollow/"
    
    // Playlist
    static let playlist = hostV1 + "playlist/"
    static let playlistList = playlist + "list/"
    static let playlistSet = playlist + "set/"
    static let playlistIntial = playlist + "initial/"
    static let playlistShared = playlist + "shared/"
    static let playlistImport = playlist + "import/"
    static let playlistDel = playlist + "del/"
    
    // Log
    static let log = hostV1 + "log/"
    static let logSearch = log + "search/"
    static let logResolve = log + "resolve/"
    static let logTrackAdd = log + "trackadd/"
    static let logPlay = log + "play/"
    static let logPlayDrop = log + "playdrop/"
    static let logPlaybackDetail = log + "playback_detail/"
    static let logPlayFailure = log + "playfailure/"
    static let logDebug = log + "debug/"
    
    // Meta
    static let meta = hostV1 + "meta/"
    static let metaVersion = meta + "version/"
    static let metaKey = meta + "key/"
    
    // Genre
    static let genre = hostV1 + "genre/"
    static let genreFavorite = genre + "favorite/"
    static let genreAddFavorite = genre + "add_favorite/"
    static let genreDelFavorite = genre + "del_favorite/"
    
    // Track
    static let track = hostV1 + "track/"
    static let trackShare = track + "shared/"
    static let trackLike = track + "like/"
    static let trackDislike = track + "dislike/"
    
    static let userTrack = hostV1 + "usertrack/"
    static let userTrackNewUploads = userTrack + "newest/"
    static let userTrackLike = userTrack + "like/"
    
    // Artist
    static let artist = hostV1 + "artist/"
    static let artistFollow = artist + "follow/"
    static let artistUnfollow = artist + "unfollow/"
    
    // Feedback
    static let feedback = hostV1 + "async/feedback/"
    
}

extension CorePath {
    // core.channel
    static let channel = host + "v1/channel/"
    static let channelFeed = channel + "feed/"
    static let channelGproxy = channel + "gproxy/"
    
    // core.search
    static let newSearch = host + "v1/search/"
}

public class CorePath {
    static var host: String {
        switch hostType {
        case .Dropbeat:
            return "http://core.dropbeat.net/api/"
        case .Coroutine, .Monocheese:
            return "http://core.coroutine.io/api/"
        }
    }
    
    // core.search
    static let search = host + "search/"
    static let searchLiveset = search + "liveset/"
    
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

