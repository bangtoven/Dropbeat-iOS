//
//  Constants.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation

class NotifyKey {
    static var playerPlay = "playPlayer"
    static var playerPrev = "prevPlayer"
    static var playerPause = "pausePlayer"
    static var playerNext = "nextPlayer"
    static var playerSeek = "seekPlayer"
    static var playerStop = "stopPlayer"
    static var updatePlaylistView = "updatePlaylistView"
    static var updatePlay = "updatePlay"
    static var updateRepeatState = "updateRepeatState"
    static var updateShuffleState = "updateShuffleState"
    static var updateQualityState = "updateQualityState"
    static var networkStatusChanged = "networkStatusChanged"
    static var appSignout = "appSignout"
    static var appSignin = "appSignin"
}

class ApiKey {
    static var google = "AIzaSyCoieDdwxgy01P7MBIdR48tFxAtyEYHPmA"
}


enum PlaylistType {
    case EXTERNAL
    case USER
}

class UserDataKey {
    static var didAutoFollow = "did_auto_follow"
}