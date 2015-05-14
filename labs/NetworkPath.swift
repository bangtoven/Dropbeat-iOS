//
//  NetworkPath.swift
//  labs

import Foundation

public class ApiPath {
    static var host = "http://hack.coroutine.io/api/v1/";
    // User
    static var user = host + "user/";
    static var userSignIn = user + "signin_fb_android/";
    static var userSelf = user + "self/";
    static var userSignOut = user + "signout/";
    static var userUnlock = user + "unlock/";
    static var userChangeEmail = user + "change_email/";
    
    // Feed
    static var feed = host + "feed/";
    
    // Playlist
    static var playlist = host + "playlist/";
    static var playlistAll = playlist + "all/";
    static var playlistSet = playlist + "set/";
    static var playlistIntial = playlist + "initial/";
    static var playlistShared = playlist + "shared/";
    static var playlistImport = playlist + "import/";
    static var playlistDel = playlist + "del/";
    
    // Log
    static var log = host + "log/";
    static var logSearch = log + "search/";
    static var logResolve = log + "resolve/";
    static var logTrackAdd = log + "trackadd/";
    static var logPlay = log + "play/";
    
    // Meta
    static var meta = host + "meta/";
    static var metaVersion = meta + "version/";
}

public class CorePath {
    static var host = "http://coroutine.io:19070/api/";
    
    // core.search
    static var search = host + "search/";
    static var searchRelated = search + "related/";
    
    // core.resolve
    static var resolve = host + "resolve/";
    
    // core.related
    static var related = host + "related/";
    
    // core.live
    static var live = host + "live/";
    static var liveTracklist = live + "tracklist/";

    // core.trending
    static var trending = host + "trending/";
    static var trendingDj = host + "dj/";
    static var trendingChart = host + "chart/";
    static var trendingTopDjs = trending + "top_djs/";
    static var trendingFeaturedPlaylist = trending + "featured_playlist/";
}
