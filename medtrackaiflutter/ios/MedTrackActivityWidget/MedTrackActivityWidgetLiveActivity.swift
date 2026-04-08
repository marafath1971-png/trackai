//
//  MedTrackActivityWidgetLiveActivity.swift
//  MedTrackActivityWidget
//
//  Created by Arafat Hossain on 8/4/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MedTrackActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MedTrackActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MedTrackActivityWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MedTrackActivityWidgetAttributes {
    fileprivate static var preview: MedTrackActivityWidgetAttributes {
        MedTrackActivityWidgetAttributes(name: "World")
    }
}

extension MedTrackActivityWidgetAttributes.ContentState {
    fileprivate static var smiley: MedTrackActivityWidgetAttributes.ContentState {
        MedTrackActivityWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MedTrackActivityWidgetAttributes.ContentState {
         MedTrackActivityWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MedTrackActivityWidgetAttributes.preview) {
   MedTrackActivityWidgetLiveActivity()
} contentStates: {
    MedTrackActivityWidgetAttributes.ContentState.smiley
    MedTrackActivityWidgetAttributes.ContentState.starEyes
}
