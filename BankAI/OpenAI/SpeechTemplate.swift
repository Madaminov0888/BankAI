//
//  SpeechTemplate.swift
//  BankAI
//
//  Created by Akbar Khusanbaev on 20/04/25.
//

import Foundation

/// Template model representing the conversational prompts and expected answer types for speech interactions.
/// Conforms to `Identifiable` for list/UI binding and `Codable` for serialization/deserialization.
struct SpeechTemplate: Identifiable, Codable {
    /// Unique identifier for the template, used in UI lists and JSON storage.
    var id: String

    /// The type of question to present to the user, with associated context.
    var questionType: QuestionType

    /// The expected format of the user's answer.
    var answerType: AnswerType

    /// Enumeration of possible question scenarios with associated parameters.
    enum QuestionType: Codable {
        /// Initial welcome and language preference inquiry.
        /// - Parameters:
        ///   - bank: Name of the bank or organization.
        ///   - client: Name of the client.
        case welcomeAndPreferredLanguage(String, String)

        /// Ask if it's a convenient time to speak.
        /// - Parameter language: Language in which to ask.
        case isConvenientTime(String)

        /// Request a better time to speak.
        /// - Parameter language: Language in which to ask.
        case whatIsConvenientTime(String)

        /// Describe student loan options.
        /// - Parameters:
        ///   - language: Language for the description.
        ///   - clientName: Full name of the client.
        ///   - clientAge: Age of the client in years.
        case initialDescribeStudentLoanOptions(String, String, Int)

        /// End the student loan discussion.
        /// - Parameter language: Language in which to conclude.
        case endStudentLoan(String)

        /// Follow up based on previous call context.
        /// - Parameters:
        ///   - language: Language for follow-up.
        ///   - callDate: Date of the previous call.
        ///   - resultOfPrevCall: Outcome of the prior conversation.
        case callbackRemindPrevCalls(String, Date, String)

        /// Clarify interest based on a prior call.
        /// - Parameters:
        ///   - language: Language for clarification.
        ///   - callDate: Date of the previous interaction.
        case clarifyRemindPrevCalls(String, Date)

        /// Remind the client about upcoming deadlines.
        /// - Parameter language: Language for the reminder.
        case remindDeadlines(String)

        /// General call-ending prompt.
        /// - Parameter language: Language in which to end the call.
        case end(String)

        /// Generates the actual prompt to send to the TTS or AI engine,
        /// selecting the right template based on the question case.
        var questionPrompt: String {
            switch self {
            case .welcomeAndPreferredLanguage(let bank, let client):
                return "Hello, this is Ash from \(bank). I'm calling to speak with \(client). I’d like to discuss some student loan opportunities that might interest you. Would you prefer to continue this conversation in English, or do you have another language preference?"

            case .isConvenientTime(let language):
                return "In \(language) language. Ask user if it is a convenient time for them to talk right now."

            case .whatIsConvenientTime(let language):
                return "In \(language) language. Ask user what is the most convenient time for them to talk. It can also be another day possibly."

            case .initialDescribeStudentLoanOptions(let language, let clientName, let clientAge):
                return """
Client information:
- Name: \(clientName)
- Age: \(clientAge)
In \(language) language. Offer student loan opportunities, highlight benefits, and ask if the client is interested in proceeding.
"""

            case .endStudentLoan(let language):
                return "In \(language) language. End the call regarding student loans."

            case .callbackRemindPrevCalls(let language, let callDate, let resultOfPrevCall):
                return """
Previous call details:
- Date: \(callDate)
- Result: \(resultOfPrevCall)
In \(language) language, follow up: 'I’m following up today to discuss our student loan options, which might help with your educational financing needs.'
"""

            case .clarifyRemindPrevCalls(let language, let callDate):
                return """
Previous call date: \(callDate)
We know that this client was interested in student loan opportunities.
In \(language) language. Ask if client is still interested in the form of speech for the dialogue of bank specialist and student, example:
'I’m following up today to discuss our student loan options, which we have discussed on \(callDate)'
"""
            case .remindDeadlines(let language):
                return "In \(language) language. Remind the client that application deadlines end in 5 business days."

            case .end(let language):
                return "In \(language) language. Conclude the call in a friendly manner."
            }
        }
    }

    /// Defines how to parse or interpret the user's response.
    enum AnswerType: String, Codable {
        /// Extract the user's preferred language (default to English).
        case preferredLanguage

        /// Expect a 'yes' or 'no' answer.
        case yesOrNo

        /// Extract a date/time in ISO format, interpreting relative terms.
        case time

        /// No parsing required; always returns success.
        case none

        /// Instructional prompt guiding downstream parsing logic.
        var answerPrompt: String {
            switch self {
            case .preferredLanguage:
                return "Extract preferred language: 'english' or 'russian'. Default to 'english'."

            case .yesOrNo:
                return "Extract response strictly as 'yes' or 'no'."

            case .time:
                return "Parse user's reply into ISO 8601 date/time. Use current context date for 'tomorrow' or time-only inputs. Return null if unparseable."

            case .none:
                return "No extraction needed; always return success."
            }
        }
    }
}

/// Array of all template IDs in the system, used for enumeration or lookup.
let allTemplates: [String] = [
    "welcome_preferred_language",
    "is_convenient_time",
    "what_is_convenient_time",
    "initial_describe_student_loan_options",
    "end_student_loan",
    "callback_remind_prev_call",
    "clarify_remind_prev_calls",
    "remind_deadlines",
    "end"
]
