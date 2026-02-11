# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpaceMolt is a **macOS-native** read-only viewer/dashboard for the SpaceMolt AI agent MMO game. It monitors a character ("Drift") being played by an AI bot (DriftBot) and displays live game state — player status, ship details, cargo, galaxy map, missions, skills, chat, and captain's log. The app is **strictly read-only** and must never call mutation endpoints.

## Build & Test Commands

```bash
# Build (macOS app — no destination needed)
xcodebuild -project SpaceMolt.xcodeproj -scheme SpaceMolt -configuration Debug build

# Run tests
xcodebuild -project SpaceMolt.xcodeproj -scheme SpaceMolt -configuration Debug test

# Run a single test
xcodebuild -project SpaceMolt.xcodeproj -scheme SpaceMolt -configuration Debug test -only-testing:SpaceMoltTests/TestClassName/testMethodName
```

Note: This is a macOS app (deployment target 26.2), not iOS. No `-destination` flag is needed for building.

## Architecture

### Networking Layer (MCP Protocol)

The game server uses **MCP (Model Context Protocol)** over HTTPS with JSON-RPC 2.0. All requests go to `https://game.spacemolt.com/mcp`.

- **`MCPClient`** — Low-level static HTTP client. Handles MCP session initialization (3-step handshake: initialize → sendInitialized → login) and `tools/call` JSON-RPC requests. Responses contain game data double-encoded as JSON inside `result.content[0].text`.
- **`SessionManager`** — `@Observable` class managing connection state and session IDs (both `mcpSessionId` and `gameSessionId`). Handles connect/disconnect/reconnect lifecycle.
- **`GameAPI`** — Type-safe wrapper over `MCPClient.callTool()`. Contains an **allowlist of read-only tools** — any tool not in `allowedTools` is blocked at runtime. All methods are generic and decode responses via `Decodable`.
- **`PollingManager`** — `@Observable` class that polls `GameAPI` at three tiers:
  - **High frequency (5s):** `get_status`, `get_cargo`
  - **Medium frequency (30s):** `get_system`, `get_nearby`, `get_active_missions`, `get_drones`, `get_chat_history`
  - **Low frequency (60s):** `get_ship`, `get_skills`, `list_ships`, `view_orders`
  - **One-time on connect:** public galaxy map, captain's log
  - Also exposes `refreshChat(channel:)` and `refreshCaptainsLog()` for on-demand refreshes.

There is also an unauthenticated REST endpoint at `GET https://game.spacemolt.com/api/map` for the galaxy map.

### App & ViewModel Layer

- **`AppViewModel`** — Root `@Observable` object. Owns `SessionManager`, creates `GameAPI`, `PollingManager`, and `MapViewModel` on connect. Holds `inspectorFocus: InspectorFocus` that drives the right inspector panel. Handles auto-connect from Keychain on launch.
- **`MapViewModel`** — Persistent map state (scale, offset, selection). Holds weak reference to `AppViewModel` to set `inspectorFocus` on system selection.
- **`SettingsViewModel`** — Authentication and credentials management, used in Settings scene.
- **`InspectorFocus`** enum (`State/InspectorFocus.swift`) — Drives right panel: `.none`, `.systemDetail(String)`, `.shipDetail`, `.missionDetail(String)`, `.skillsOverview`, `.cargoDetail`, `.nearbyDetail`.

### View Layer — Hub Layout

Uses a persistent multi-pane "command center" layout (no sidebar/tab navigation):

```
+-------------------------------------------------------------------+
|  Toolbar (connection status, polling indicator)                   |
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
|  BOTTOM BAR: Chat | Captain's Log | Alerts     (~150px)          |
+-------------------------------------------------------------------+
```

- **`HubView`** — Root view. Shows `ConnectedHubView` when connected, login prompt otherwise.
- **`ConnectedHubView`** — HSplitView/VSplitView skeleton composing all panels.
- **Left Panel** (`Views/StatusPanel/`): `StatusPanelView` composing compact widgets — `PlayerIdentityCompact`, `LocationCompact`, `ShipVitalsCompact`, `NearbyCompact`, `MissionsCompact`, `CargoCompact`, `ConnectionStatusCompact`. Each tappable widget sets `inspectorFocus`.
- **Center** (`Views/Map/`): `GalaxyMapView` with `MapControlsView`, empire legend, current system label. System taps set `inspectorFocus`.
- **Right Panel** (`Views/Inspector/`): `InspectorPanelView` switches on `InspectorFocus` to show `SystemInspectorView`, `ShipInspectorView`, `MissionInspectorView`, `SkillsInspectorView`, `CargoInspectorView`, `NearbyInspectorView`, or `InspectorEmptyView`.
- **Bottom Bar** (`Views/ActivityBar/`): `ActivityBarView` with tab strip for `ChatFeedView`, `LogFeedView`, `AlertsFeedView`.
- **Settings** available via Cmd+, (macOS Settings scene).

Minimum window size: 1100x700. Dark mode forced.

### Services

- **`KeychainService`** — Persists username/password hash to macOS Keychain for auto-login.
- **`SMLog`** — Centralized `OSLog` logging via categories: `.general`, `.network`, `.auth`, `.polling`, `.api`, `.keychain`, `.ui`, `.map`, `.decode`.

### Models

All model structs are `Decodable` + `Sendable` with explicit `CodingKeys` mapping `snake_case` JSON to `camelCase` Swift properties. `ShipOverview` has computed percent properties (`hullPercent`, `shieldPercent`, `fuelPercent`, `cargoPercent`).

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
- **Safety-first networking**: `GameAPI.allowedTools` whitelist prevents accidental mutation calls. Never add mutation tools to this list.
- **Progressive disclosure**: Compact widgets in left panel are tappable → sets `inspectorFocus` → right panel shows detail. No popovers, no sheets, no navigation stacks. One consistent pattern.
- **Logging**: Use `SMLog.<category>` throughout. Available categories defined in `Services/Logger.swift`.
- **Bundle ID**: `com.saygoodnight.SpaceMolt`

## API Reference

Full API documentation including all endpoint response shapes is in `docs/VIEWER_API_REFERENCE.md`.
