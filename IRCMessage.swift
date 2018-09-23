//
//  IRCMessage.swift
//
//  Created by Peter de Tagyos on 8/22/17.
//  Copyright © 2017 Peter de Tagyos. All rights reserved.
//

import Foundation

struct IRCMessage {
    var prefix: String? = nil
    var command: String!
    var parameters: String!
    var customPayload: String? = nil
}
