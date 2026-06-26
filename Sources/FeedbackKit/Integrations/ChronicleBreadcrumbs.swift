//
//  ChronicleBreadcrumbs.swift
//  FeedbackKit
//
//  Snapshots recent Chronicle events into a Codable summary so "what the user did
//  right before" travels with the report.
//

import Foundation
import Chronicle

enum ChronicleBreadcrumbs {
	static func collect(limit: Int) async -> [BreadcrumbSummary]? {
		guard limit > 0 else { return nil }
		guard let events = await Chronicle.instance.events?.recentEvents(limit: limit), !events.isEmpty else { return nil }
		return events.map { event in
			BreadcrumbSummary(
				name: event.name,
				timestamp: event.timestamp,
				context: event.context.map { meta in meta.dictionary.mapValues { "\($0)" } },
				source: event.sourceFunction
			)
		}
	}
}
