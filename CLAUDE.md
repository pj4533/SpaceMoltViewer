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

There is also an unauthenticated REST endpoint at `GET https://game.spacemolt.com/api/map` for the galaxy map.

### App & ViewModel Layer

- **`AppViewModel`** — Root `@Observable` object. Owns `SessionManager`, creates `GameAPI` and `PollingManager` on connect. Handles auto-connect from Keychain on launch.
- **Per-tab ViewModels** (`DashboardViewModel`, `ShipViewModel`, `MapViewModel`, `SkillsViewModel`, `MissionsViewModel`, `SocialViewModel`, `LogViewModel`, `SettingsViewModel`) — Each takes `PollingManager` and exposes computed properties from polled data. Created fresh by `ContentView` when switching tabs.

### View Layer

Uses `NavigationSplitView` with a sidebar (`SidebarTab` enum) and detail views. Tabs: Dashboard, Ship, Galaxy Map, Skills, Missions, Social, Captain's Log, Settings. Views show "Not Connected" placeholder when `pollingManager` is nil.

### Services

- **`KeychainService`** — Persists username/password hash to macOS Keychain for auto-login.
- **`SMLog`** — Centralized `OSLog` logging via categories: `.general`, `.network`, `.auth`, `.polling`, `.api`, `.keychain`, `.ui`, `.map`, `.decode`.

### Models

All model structs are `Decodable` + `Sendable` with explicit `CodingKeys` mapping `snake_case` JSON to `camelCase` Swift properties.

## Key Conventions

- **Observation framework**: Uses `@Observable` (not Combine/ObservableObject). ViewModels are classes marked `@Observable`, views use `@Bindable` or direct property access.
- **Safety-first networking**: `GameAPI.allowedTools` whitelist prevents accidental mutation calls. Never add mutation tools to this list.
- **Logging**: Use `SMLog.<category>` throughout. Available categories defined in `Services/Logger.swift`.
- **Bundle ID**: `com.saygoodnight.SpaceMolt`

## API Reference

Full API documentation including all endpoint response shapes is in `docs/VIEWER_API_REFERENCE.md`.
