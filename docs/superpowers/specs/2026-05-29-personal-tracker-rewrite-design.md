# Personal Tracker Rewrite Design

## Approval Status

Approved direction: **Personal Tracker**.

This rewrite keeps the app native to iOS and shifts the product from a generic diary toward a private, customizable tracker for daily records, structured fields, and personal insights. The rewritten app should make custom trackers, typed entries, and trends feel like the primary product, not an add-on to journaling.

## Current App Summary

The existing app is a SwiftUI and SwiftData iOS app named `Diary`. It supports multiple diaries, custom field definitions, entry creation, entry detail views, and a chart view. The current schema is centered around `Diary`, `FieldDef`, and `Entry`, with field values stored in dictionaries keyed by field names.

The core feature idea is strong: users can define the shape of what they want to record. The rewrite should preserve that idea while fixing durability, testability, navigation, and visual identity issues before adding new behavior.

## Product Requirements

1. The app remains a native iOS app built with SwiftUI, SwiftData, and Apple platform UI conventions.
2. Users can create multiple custom trackers.
3. Each tracker can define fields for text, numeric values, dates, times, and selectable options.
4. Users can create, browse, and inspect entries for each tracker.
5. Entries preserve the field definitions that existed when they were created, even when fields are renamed, reordered, or edited later.
6. Numeric fields support useful trend charts over entry dates, and date/time values can be used for grouping or filtering when the chart design calls for it.
7. Data remains local and private by default.
8. The app receives a new name, icon, accent color, and visual system aligned with the Personal Tracker direction.
9. The rewritten app includes automated tests for model behavior, persistence, chart aggregation, and core UI flows.

## Non-Goals

1. No cloud sync in this rewrite.
2. No user accounts in this rewrite.
3. No social, sharing, or collaboration features in this rewrite.
4. No cross-platform rewrite; the app stays native iOS.
5. No broad feature expansion until the data model, migration, tests, and core UX are stable.

## Architecture

The rewrite should separate domain logic from SwiftData storage and SwiftUI views.

The domain layer owns stable concepts: tracker identity, field identity, field type, field options, entry value, validation, and chart aggregation. Domain types should be small, testable Swift structs and enums where possible.

The persistence layer owns SwiftData models, schema versioning, and migration. SwiftData models should not rely on field names as durable identifiers. Field definitions need stable IDs, and entry values should reference field IDs or a versioned field snapshot.

The use-case layer coordinates transactions such as creating a tracker, editing a schema, creating an entry, and generating chart data. SwiftUI views should call these focused operations rather than directly assembling persistence behavior in view bodies.

The view layer owns navigation, form state, empty states, accessibility labels, and visual presentation. Views should edit draft values first, validate them through domain/use-case code, then persist through explicit save operations.

## Data Model Requirements

Trackers replace the user-facing concept of diaries. Source code may keep transitional names temporarily during migration, but new domain APIs and UI copy should prefer `Tracker`.

Each tracker has:

1. A stable ID.
2. A display name.
3. An ordered list of field definitions.
4. An ordered or date-sorted collection of entries.
5. Created and updated timestamps.

Each field definition has:

1. A stable field ID that never changes when the field is renamed.
2. A display name.
3. A field type.
4. Optional selector options.
5. Ordering metadata.
6. Schema version metadata when needed for migration and entry interpretation.

Each entry has:

1. A stable ID.
2. A tracker ID relationship.
3. A creation timestamp.
4. A values collection keyed by stable field ID.
5. Enough field snapshot information to render old entries correctly after schema edits.

Entry values should be typed. A numeric field stores a number, a date field stores a date, a time field stores time data, a selector field stores a selected option identity or value, and a text field stores text. Avoid `Any` at persistence and domain boundaries.

## Migration Requirements

The rewrite needs an explicit migration path from the current SwiftData shape to the new model. Existing field names should be converted into stable field IDs during migration. Existing entries should retain their values and be renderable after migration.

If an old entry has malformed or missing values, migration should keep the entry and mark the invalid value as unavailable rather than dropping the entire entry.

The migration should be tested with representative old data:

1. A tracker with text, numeric, date, time, and selector fields.
2. Entries with complete values.
3. Entries with missing values.
4. A converted old tracker whose field is renamed after migration, proving old entries still render against stable field IDs.

## User Experience Requirements

The app opens to a tracker list, not a marketing page. Empty states should help users create their first tracker without lengthy explanation.

Tracker detail should make entry creation, recent entries, fields, and insights easy to reach. The rewritten navigation should avoid nested `NavigationStack` ownership inside child screens.

Entry creation should use native form controls, toolbar save/cancel actions, and clear validation feedback. Field editors should distinguish display names, field types, and selector options cleanly.

Charts should only offer compatible fields. Numeric charts should use numeric fields. Selector charts may be considered later, but they are not required for the first rewrite unless the chart agent finds a narrow, testable implementation.

Accessibility is part of the baseline. Primary actions, field controls, rows, and charts need stable labels or identifiers for UI testing and VoiceOver.

## Visual Identity Requirements

The new identity should communicate private custom tracking rather than generic diary writing.

The name should be short, memorable, and compatible with a utility app. The final name is still an interactive decision. Candidate directions include names that suggest fields, patterns, personal metrics, daily records, or gentle insight.

The icon should visually connect to structured tracking. Preferred metaphors include field rows, a checkmark, a chart point, a personal dashboard mark, or a compact grid. Avoid a generic book-only icon unless it is paired with a clear structured-data cue.

The visual system should be calm and readable, with enough personality to feel polished. It should use restrained system-native layout, a distinctive accent color, strong contrast, and compact information hierarchy suitable for repeated daily use.

## Agent Work Graph

The work should proceed through one serial critical path with parallel lanes once contracts are stable.

Critical path:

1. Approved spec.
2. Test seams and baseline fixtures.
3. Domain model with stable field IDs and typed values.
4. SwiftData v2 schema and migration.
5. SwiftUI rewire.
6. Full QA and polish.

Parallel agent lanes:

1. Model and Persistence Agent: owns domain types, SwiftData schema, migration, and repository transactions.
2. UI and Accessibility Agent: owns navigation cleanup, forms, empty states, visual system, and accessibility identifiers.
3. Charts Agent: owns aggregation logic, compatible field filtering, chart UI, and chart tests.
4. QA Agent: owns test fixtures, unit tests, UI smoke flows, simulator verification, and regression notes.

The main thread keeps the interactive decisions: final app name, icon direction, scope approvals, and review of integration checkpoints.

## Testing Requirements

The rewrite should add launch arguments for UI testing, including a way to reset local state and seed deterministic sample data.

Unit tests should cover:

1. Field identity surviving rename and reorder operations.
2. Entry value validation by field type.
3. Entry rendering from field snapshots.
4. Chart aggregation from numeric fields.
5. Migration from representative old data.

UI tests should cover:

1. Creating a tracker.
2. Adding fields.
3. Creating an entry.
4. Viewing the entry detail.
5. Viewing compatible charts.
6. Empty-state behavior.

Simulator verification should include at least one successful build and one successful automated UI flow on an iOS Simulator.

## Error Handling

Validation errors should be visible before saving when possible. Persistence failures should not be silently swallowed. Any save failure should produce a user-visible error state and a developer-visible log message.

Migration should prefer preserving data over perfect conversion. Invalid individual values can be marked unavailable, but trackers and entries should remain accessible when possible.

## Implementation Gate

Implementation should not begin until this spec is reviewed. After review, the next artifact is a task-level implementation plan saved under `docs/superpowers/plans/`.
