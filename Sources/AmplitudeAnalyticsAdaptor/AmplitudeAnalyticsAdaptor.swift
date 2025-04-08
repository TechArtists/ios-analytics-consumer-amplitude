/*
MIT License

Copyright (c) 2025 Tech Artists Agency

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
public class AmplitudeAnalyticsAdaptor: AnalyticsAdaptor, AnalyticsAdaptorWithReadWriteUserID {
    
    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    private let apiKey: String
    private let isRedacted: Bool
    private var amplitude: Amplitude?

    // MARK: AnalyticsAdaptor

    /// - Parameters:
    ///   - isRedacted: If parameter & user property values should be redacted.
    ///   - enabledInstallTypes: Install types for which the consumer is enabled.
    public init(apiKey: String, enabledInstallTypes: [TAAnalyticsConfig.InstallType] = TAAnalyticsConfig.InstallType.allCases, isRedacted: Bool = true) {
        self.enabledInstallTypes = enabledInstallTypes
        self.isRedacted = isRedacted
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

    public func track(trimmedEvent: EventAnalyticsModelTrimmed, params: [String: any AnalyticsBaseParameterValue]?) {
        
        var eventProperties = [String: Any]()
        if let params = params {
            for (key, value) in params {
                eventProperties[key] = value.description
            }
        }
        
        let baseEvent = BaseEvent(
            eventType: trimmedEvent.rawValue,
            eventProperties: eventProperties
        )
        amplitude?.track(event: baseEvent)
    }

    public func set(trimmedUserProperty: UserPropertyAnalyticsModelTrimmed, to: String?) {
        let userPropertyKey = trimmedUserProperty.rawValue
        
        var userProperties = [String: Any]()
        if let value = to {
            userProperties[userPropertyKey] = value
        } else {
            // You may want to remove the user property if `to` is nil
            userProperties[userPropertyKey] = NSNull()
        }

        amplitude?.identify(userProperties: userProperties)
    }

    public func trim(event: EventAnalyticsModel) -> EventAnalyticsModelTrimmed {
        EventAnalyticsModelTrimmed(event.rawValue.ta_trim(toLength: 240, debugType: "event"))
    }

    public func trim(userProperty: UserPropertyAnalyticsModel) -> UserPropertyAnalyticsModelTrimmed {
        UserPropertyAnalyticsModelTrimmed(userProperty.rawValue.ta_trim(toLength: 40, debugType: "user property"))
    }

    public var wrappedValue: Amplitude {
        guard let amplitude = amplitude else {
            fatalError("Amplitude instance has not been initialized. Call startFor(...) before accessing wrappedValue.")
        }
        return amplitude
    }

    // MARK: AnalyticsAdaptorWithWriteOnlyUserID

    public func set(userID: String?) {
        amplitude?.setUserId(userId: userID)
    }
    
    public func getUserID() -> String? {
        amplitude?.getUserId()
    }
}
