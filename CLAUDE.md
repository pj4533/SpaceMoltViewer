# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpaceMoltViewer is a **macOS-native** read-only viewer/dashboard for the SpaceMolt AI agent MMO game. It monitors a character ("Drift") being played by an AI bot (DriftBot) and displays live game state — player status, ship details, cargo, galaxy map, missions, skills, chat, and captain's log. The app is **strictly read-only** and must never call mutation endpoints.

## Build & Test Commands

```bash
# Build (macOS app — no destination needed)
xcodebuild -project SpaceMoltViewer.xcodeproj -scheme SpaceMoltViewer -configuration Debug build

# Run tests
xcodebuild -project SpaceMoltViewer.xcodeproj -scheme SpaceMoltViewer -configuration Debug test

# Run a single test
xcodebuild -project SpaceMoltViewer.xcodeproj -scheme SpaceMoltViewer -configuration Debug test -only-testing:SpaceMoltViewerTests/TestClassName/testMethodName
```

Note: This is a macOS app (deployment target 26.2), not iOS. No `-destination` flag is needed for building.

## Architecture

### Networking Layer (WebSocket)

The app uses a **WebSocket** connection to `wss://game.spacemolt.com/ws` for real-time game data. The server pushes `state_update` every tick (~10s) with player/ship/nearby data, plus real-time events (combat, chat, mining, skill-ups, etc.).

- **`WebSocketClient`** — Core transport layer using `URLSessionWebSocketTask`. Handles connection, login, message routing, and automatic reconnection with exponential backoff. Contains an **allowlist of read-only queries** — any query not in `allowedQueries` is blocked at runtime. Push events are delivered via `AsyncStream<WSRawMessage>`, query responses are routed to pending continuations.
- **`SessionManager`** — `@Observable` class managing connection state. Handles connect (WebSocket + login) and disconnect lifecycle. Stores the `WebSocketClient` instance.
- **`GameStateManager`** — `@Observable` class replacing the old polling system. Subscribes to the WebSocket message stream and updates all game state properties from push events. Also handles on-demand queries for data not covered by push events (skills, missions, ship details, etc.) and a lightweight periodic refresh (~30s) for supplementary data.

There is also an unauthenticated REST endpoint at `GET https://game.spacemolt.com/api/map` for the galaxy map (fetched by `GameStateManager`).

### WebSocket Message Types

**Push events (server → client):**
- `state_update` — Every tick: player, ship, nearby, combat status, travel progress
- `chat_message` — Real-time chat messages
- `combat_update` — Combat hit details
- `mining_yield` — Mining results
- `skill_level_up` — Skill level increases
- `poi_arrival`/`poi_departure` — Player arrivals/departures at POIs
- `ok` — Action confirmations from DriftBot (travel, dock, mine, etc.)
- `gameplay_tip` — Server tips

**Queries (client → server → client):**
- Send: `{"type": "<tool_name>", "payload": {...}}`
- Response: `{"type": "ok", "payload": {"action": "<tool_name>", ...data...}}`

### App & ViewModel Layer

- **`AppViewModel`** — Root `@Observable` object. Owns `SessionManager`, creates `GameStateManager` and `MapViewModel` on connect. Holds `inspectorFocus: InspectorFocus` that drives the right inspector panel. Handles auto-connect from Keychain on launch.
- **`MapViewModel`** — Persistent map state (scale, offset, selection). Holds weak reference to `AppViewModel` to set `inspectorFocus` on system selection.
- **`SettingsViewModel`** — Authentication and credentials management, used in Settings scene.
- **`InspectorFocus`** enum (`State/InspectorFocus.swift`) — Drives right panel: `.none`, `.systemDetail(String)`, `.shipDetail`, `.missionDetail(String)`, `.skillsOverview`, `.cargoDetail`, `.nearbyDetail`.

### View Layer — Hub Layout

Uses a persistent multi-pane "command center" layout (no sidebar/tab navigation):

```
+-------------------------------------------------------------------+
|  Toolbar (connection status, Live indicator)                      |
+-------------------+---------------------------+-------------------+
|   LEFT PANEL      |      CENTER PANE          |   RIGHT PANEL     |
|   StatusPanel     |      Galaxy Map           |   Inspector       |
|   (~240px)        |      (flexible fill)      |   (~280px)        |
|                   |                           |                   |
|   PlayerIdentity  |      Canvas map with      |   Context-driven  |
|   Location        |      zoom/pan/click       |   detail panel    |
|   ShipVitals      |                           |   (InspectorFocus)|
|   Nearby          |      Empire legend        |                   |
|   Missions        |      Map controls         |                   |
|   Cargo           |      Current system label |                   |
|   Skills          |                           |                   |
|   Connection      |                           |                   |
+-------------------+---------------------------+-------------------+
|  BOTTOM BAR: Events | Chat | Captain's Log     (~150px)          |
+-------------------------------------------------------------------+
```

- **`HubView`** — Root view. Shows `ConnectedHubView` when connected, login prompt otherwise.
- **`ConnectedHubView`** — HSplitView/VSplitView skeleton composing all panels.
- **Left Panel** (`Views/StatusPanel/`): `StatusPanelView` composing compact widgets — `PlayerIdentityCompact`, `LocationCompact`, `ShipVitalsCompact`, `NearbyCompact`, `MissionsCompact`, `CargoCompact`, `ConnectionStatusCompact`. Each tappable widget sets `inspectorFocus`.
- **Center** (`Views/Map/`): `GalaxyMapView` with `MapControlsView`, empire legend, current system label. System taps set `inspectorFocus`.
- **Right Panel** (`Views/Inspector/`): `InspectorPanelView` switches on `InspectorFocus` to show `SystemInspectorView`, `ShipInspectorView`, `MissionInspectorView`, `SkillsInspectorView`, `CargoInspectorView`, `NearbyInspectorView`, or `InspectorEmptyView`.
- **Bottom Bar** (`Views/ActivityBar/`): `ActivityBarView` with tab strip for `EventsFeedView` (real-time game events), `ChatFeedView`, `LogFeedView`.
- **Settings** available via Cmd+, (macOS Settings scene).

Minimum window size: 1100x700. Dark mode forced.

### Services

- **`KeychainService`** — Persists username/password hash to macOS Keychain for auto-login.
- **`SMLog`** — Centralized `OSLog` logging via categories: `.general`, `.network`, `.auth`, `.polling`, `.api`, `.keychain`, `.ui`, `.map`, `.decode`, `.websocket`.

### Models

All model structs are `Decodable` + `Sendable` with explicit `CodingKeys` mapping `snake_case` JSON to `camelCase` Swift properties. `ShipOverview` has computed percent properties (`hullPercent`, `shieldPercent`, `fuelPercent`, `cargoPercent`).

WebSocket-specific models in `Models/WebSocketPayloads.swift` (WelcomePayload, StateUpdatePayload, etc.) and `Models/GameEvent.swift` (GameEvent, GameEventCategory with color/emoji).

### Shared Components

- `Views/Shared/GaugeRow.swift` — Reusable progress bar with label/value
- `Views/Shared/StatLabel.swift` — Reusable stat display (value + label)
- `Views/Shared/EmptyStateView.swift` — Placeholder for empty/loading states
- `Views/Shared/ConnectionIndicator.swift` — Colored dot + status text

### Reusable Sub-views (kept from original)

- `SkillRowView`, `MissionRowView`, `ModuleListView`, `ShipStatsView` — Used by inspector views
- `ChatChannelView`, `ChatMessageRow`, `LogEntryView` — Used by activity bar feeds

## Key Conventions

- **Observation framework**: Uses `@Observable` (not Combine/ObservableObject). ViewModels are classes marked `@Observable`, views use `@Bindable` or direct property access.
- **Safety-first networking**: `WebSocketClient.allowedQueries` whitelist prevents accidental mutation calls. Never add mutation tools to this list.
- **Progressive disclosure**: Compact widgets in left panel are tappable -> sets `inspectorFocus` -> right panel shows detail. No popovers, no sheets, no navigation stacks. One consistent pattern.
- **Logging**: Use `SMLog.<category>` throughout. Available categories defined in `Services/Logger.swift`.
- **Bundle ID**: `com.saygoodnight.SpaceMoltViewer`

## API Reference

Full API documentation including all endpoint response shapes is in `docs/VIEWER_API_REFERENCE.md`.
