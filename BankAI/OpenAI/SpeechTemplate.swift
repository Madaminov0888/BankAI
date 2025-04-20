//
//  SpeechTemplate.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 20/04/25.
//

import Foundation

struct SpeechTemplate: Identifiable, Codable {
    var id: String
    var questionType: QuestionType
    var answerType: AnswerType
    
    enum QuestionType: Codable {
        case welcomeAndPreferredLanguage(String, String)
        case isConvenientTime(String), whatIsConvenientTime(String)
        case initialDescribeStudentLoanOptions(String, String, Int), endStudentLoan(String)
        case callbackRemindPrevCalls(String, Date, String)
        case clarifyRemindPrevCalls(String, Date), remindDeadlines(String)
        case end(String)
        
        var questionPrompt: String {
            switch self {
            case .welcomeAndPreferredLanguage(let bank, let client):
                "Hello, this is Ash from \(bank). I'm calling to speak with \(client), I’d like to discuss some student loan opportunities that might interest you. Would you prefer to continue this conversation in English, or do you have another language preference?"
            case .isConvenientTime(let language):
                "In \(language) language. Ask user is it convenient time for them to talk right now?"
            case .whatIsConvenientTime(let language):
                "In \(language) language. Ask user what is the most convenient time for them to talk? It can also be another day possibly"
            case .initialDescribeStudentLoanOptions(let language, let clientName, let clientAge, ):
                """
Client informations are as follows.
Name: \(clientName)
Age: \(clientAge)
In \(language) language. You should offer a client a bank loan opportunities. Mention how cool the student loan is. At the end ask if client is interested in obtaining that.
"""
            case .endStudentLoan(let language):
                "In \(language) language. End call with the customer."
            case .callbackRemindPrevCalls(let language, let callDate, let resultOfPrevCall):
                """
Informations that we know.
Previous call date: \(callDate)
Previous call result: \(resultOfPrevCall)
In \(language) language. Depending on previous call result, express the following text in the form of speech for the dialogue of bank specialist and student: 
'I’m following up today to discuss our student loan options, which might help with your educational financing needs.'
"""
            case .clarifyRemindPrevCalls(let language, let callDate):
                """
Informations that we know.
Previous call date: \(callDate)
We know that this client was interested in student loan opportunities.
In \(language) language. Ask if client is still interested in the form of speech for the dialogue of bank specialist and student, example:
'I’m following up today to discuss our student loan options, which we have discussed on \(callDate)'
"""
            case .remindDeadlines(let language):
                "In \(language) language. Remind a client that the deadlines end in 5 business days."
            case .end(let language):
                "In \(language) language. End call with the customer in a friendly way."
            }
        }
    }
    
    enum AnswerType: String, Codable {
        case preferredLanguage
        case yesOrNo
        case time
        case none
        
        var answerPrompt: String {
            switch self {
            case .preferredLanguage:
                "From user's response you should extract preferred language in the form of string. Accepted languages are: english, russian. If user says any other language send 'english' by default"
            case .yesOrNo:
                "From user's response you should extract information in the form of 'yes' or 'no'. Nothing else."
            case .time:
                "From user's response you should extract date time in the ISO format. User could possibly say tomorrow, so knowing that right now is \(Date()) you should respond with user's date in the form of ISO date. If user says just time suppose that the date is today (\(Date())). If you couldn't understand, just return null."
            case .none:
                "Just return true to anything user says"
            }
        }
    }
}

let allTemplates: [SpeechTemplate.ID] = [
    "welcome_preferred_language",
    "is_convenient_time",
    "what_is_convenient_time",
    "init_describe_student_loan_options",
    "end_student_loan",
    "callback_remind_prev_call",
    "clarify_remind_prev_calls",
    "remind_deadlines",
    "end"
]
