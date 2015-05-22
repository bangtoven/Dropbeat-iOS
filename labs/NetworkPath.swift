//
//  NetworkPath.swift
//  labs

import Foundation

public class ApiPath {
    static var host :String = "http://spark.coroutine.io/api/v1/"
    
    // User
    static var user :String = host + "user/"
    static var userSignIn :String = user + "signin_fb_android/"
    static var userSelf :String = user + "self/"
    static var userSignOut :String = user + "signout/"
    static var userUnlock :String = user + "unlock/"
    static var userChangeEmail :String = user + "change_email/"
    
    // Feed
    static var feed :String = host + "feed/"
    
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
    
    // Meta
    static var meta :String = host + "meta/"
    static var metaVersion :String = meta + "version/"
}

public class CorePath {
    static var host :String = "http://coroutine.io:19070/api/"
    
    // core.search
    static var search :String = host + "search/"
    static var searchRelated :String = search + "related/"
    
    // core.resolve
    static var resolve :String = host + "resolve/"
    
    // core.related
    static var related :String = host + "related/"
    
    // core.live
    static var live :String = host + "live/"
    static var liveTracklist :String = live + "tracklist/"

    // core.trending
    static var trending :String = host + "trending/"
    static var trendingDj :String = host + "dj/"
    static var trendingChart :String = host + "chart/"
    static var trendingTopDjs :String = trending + "top_djs/"
    static var trendingFeaturedPlaylist :String = trending + "featured_playlist/"
}

public class ResolvePath {
    static var host :String = "http://14.63.224.95:19001/"
    static var resolveStream :String = host + "resolve/"
}