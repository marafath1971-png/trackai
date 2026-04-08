import ActivityKit
import WidgetKit
import SwiftUI

struct MedTrackActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var medName: String
        var dose: String
        var timeLeft: String
    }
}

struct MedTrackActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MedTrackActivityAttributes.self) { context in
            // Lock screen / Banner UI
            VStack {
                HStack {
                    Text("💊 Time to take \(context.state.medName)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(context.state.timeLeft)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .activityBackgroundTint(Color.black)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text("💊 \(context.state.medName)")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timeLeft)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Dose: \(context.state.dose)")
                }
            } compactLeading: {
                Text("💊")
            } compactTrailing: {
                Text(context.state.timeLeft)
            } minimal: {
                Text("💊")
            }
        }
    }
}

