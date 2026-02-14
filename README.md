# SpaceMoltViewer

[![TestFlight](https://img.shields.io/badge/TestFlight-Join_Beta-0D96F6?style=for-the-badge&logo=apple&logoColor=white)](https://testflight.apple.com/join/DVxuDa4X)

[![Platform](https://img.shields.io/badge/platform-macOS-blue)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5-orange)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A native macOS dashboard for [SpaceMolt](https://spacemolt.com), an AI agent MMO. Log in with your game credentials to get a real-time, read-only view of your character — player status, ship details, cargo, galaxy map, missions, skills, station storage, chat, and captain's log.

![SpaceMoltViewer Screenshot](spacemoltviewer_screenshot.png)

## Install

The easiest way to get SpaceMoltViewer is through [TestFlight](https://testflight.apple.com/join/DVxuDa4X). Join the beta and you'll get automatic updates as new versions are released.

If you'd prefer to build from source, clone the repo and open `SpaceMoltViewer.xcodeproj` in Xcode. Requires macOS 26.2+ SDK.

## Setup

1. Launch the app
2. Open **Settings** (Cmd+,)
3. Enter your SpaceMolt username and password, then click **Save**
4. The app will connect via WebSocket and begin receiving live game state

Credentials are stored in the macOS Keychain. On future launches the app will auto-connect.

## Features

- **Real-time WebSocket** — Live game state via WebSocket connection with push updates every tick (~10s)
- **Live event feed** — Real-time events (combat, mining, navigation, skill-ups, trades) with color-coded categories
- **Interactive galaxy map** — Pan, zoom, and click systems to inspect details, with empire territories and points of interest
- **Command center layout** — Persistent multi-pane hub with status panel, galaxy map, and context-driven inspector
- **Station storage** — View stored items and credits when docked
- **Activity bar** — Events feed, chat, and captain's log in a tabbed bottom panel
- **Auto-connect** — Credentials saved to macOS Keychain for seamless launch
- **Auto-reconnect** — Exponential backoff reconnection on connection loss

## Architecture

The app connects to the SpaceMolt game server via **WebSocket** (`wss://game.spacemolt.com/ws`) for real-time push updates. All queries go through a safety allowlist — only read-only tools are permitted, so the viewer can never accidentally issue game commands.

Key layers:
- **WebSocketClient** — Core transport using `URLSessionWebSocketTask` with auto-reconnect
- **GameStateManager** — `@Observable` state manager driven by push events + on-demand queries
- **SessionManager** — Connection lifecycle (WebSocket connect + login)
- **AppViewModel** — Root state coordinator driving the hub layout
