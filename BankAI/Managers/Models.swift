//
//  Models.swift
//  ExampleProject
//
//  Created by Muhammadjon Madaminov on 19/04/25.
//

import Foundation


struct PostCallResultRequest: Codable {
    let callId: Int
    let callResult: String
    let clientResponse: String?
    let preferredLang: String?
    let newDatetime: String?

    enum CodingKeys: String, CodingKey {
        case callId = "call_id"
        case callResult = "call_result"
        case clientResponse = "client_response"
        case preferredLang = "preferred_lang"
        case newDatetime = "new_datetime"
    }
}



struct Client: Codable {
    let clientId: Int
    let fullName: String
    let age: Int
    let preferredLang: String
    let previousCalls: [Call]
    let currentCall: Call?

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case fullName = "full_name"
        case age
        case preferredLang = "preferred_lang"
        case previousCalls = "previous_calls"
        case currentCall = "current_call"
    }
}


struct Call: Codable {
    let callId: Int
    let callDatetime: String // ISO 8601 format from Python's `datetime.isoformat()`
    let notificationType: String
    let callResult: String?
    let clientResponse: String?
    let callStatus: String

    enum CodingKeys: String, CodingKey {
        case callId = "call_id"
        case callDatetime = "call_datetime"
        case notificationType = "notification_type"
        case callResult = "call_result"
        case clientResponse = "client_response"
        case callStatus = "call_status"
    }
}

