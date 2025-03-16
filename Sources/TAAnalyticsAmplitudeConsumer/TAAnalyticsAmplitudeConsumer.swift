/*
MIT License

Copyright (c) 2025 Tataru Robert

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Foundation
import TAAnalytics
import AmplitudeSwift

/// Sends messages to Amplitude about analytics events & user properties.
public class AmplitudeAnalyticsConsumer: AnalyticsConsumer, AnalyticsConsumerWithReadWriteUserID {

    public typealias T = AmplitudeAnalyticsConsumer

    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    let apiKey: String
    var amplitude: Amplitude?

    // MARK: AnalyticsConsumer

    /// - Parameters:
    ///   - isRedacted: If parameter & user property values should be redacted.
    ///   - enabledInstallTypes: Install types for which the consumer is enabled.
    init(apiKey: String, enabledInstallTypes: [TAAnalyticsConfig.InstallType]) {
        self.enabledInstallTypes = enabledInstallTypes
        self.apiKey = apiKey
    }

    public func startFor(
        installType: TAAnalyticsConfig.InstallType,
        userDefaults: UserDefaults,
        TAAnalytics: TAAnalytics
    ) async throws {
        if !self.enabledInstallTypes.contains(installType) {
            throw InstallTypeError.invalidInstallType
        }

        self.amplitude = Amplitude(configuration: Configuration(
            apiKey: apiKey,
            autocapture: []
        ))
    }

    public func track(trimmedEvent: TrimmedEvent, params: [String: AnalyticsBaseParameterValue]?) {
        let event = trimmedEvent.event
        
        var eventProperties = [String: Any]()
        if let params = params {
            for (key, value) in params {
                eventProperties[key] = value.description
            }
        }
        
        let baseEvent = BaseEvent(
          eventType: event.rawValue,
          eventProperties: eventProperties
        )
        amplitude?.track(event: baseEvent)
    }

    public func set(trimmedUserProperty: TrimmedUserProperty, to: String?) {
        let userPropertyKey = trimmedUserProperty.userProperty.rawValue
        
        var userProperties = [String: Any]()
        if let value = to {
            userProperties[userPropertyKey] = value
        } else {
            // You may want to remove the user property if `to` is nil
            userProperties[userPropertyKey] = NSNull()
        }

        amplitude?.identify(userProperties: userProperties)
    }

    public func trim(event: AnalyticsEvent) -> TrimmedEvent {
        // Amplitude doesn't have strict event name limits, but you can enforce one.
        let trimmedEventName = event.rawValue.ob_trim(type: "event", toLength: 40)
        return TrimmedEvent(trimmedEventName)
    }

    public func trim(userProperty: AnalyticsUserProperty) -> TrimmedUserProperty {
        // Amplitude doesn't have strict user property key limits, but you can enforce one.
        let trimmedUserPropertyKey = userProperty.rawValue.ob_trim(type: "user property", toLength: 40)
        return TrimmedUserProperty(trimmedUserPropertyKey)
    }

    public var wrappedValue: Self {
        return self
    }

    // MARK: AnalyticsConsumerWithWriteOnlyUserID

    public func set(userID: String?) {
        if let userID = userID {
            amplitude?.setUserId(userId: userID)
        }
    }
    
    public func getUserID() -> String? {
        return amplitude?.getUserId()
    }
}
