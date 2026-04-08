//
//  MedTrackActivityWidgetBundle.swift
//  MedTrackActivityWidget
//
//  Created by Arafat Hossain on 8/4/26.
//

import WidgetKit
import SwiftUI

@main
struct MedTrackActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        MedTrackActivityWidget()
        MedTrackActivityWidgetControl()
        MedTrackActivityWidgetLiveActivity()
    }
}
