import SwiftUI

struct GalaxyMapView: View {
    @Bindable var viewModel: MapViewModel

    var body: some View {
        ZStack {
            if viewModel.systems.isEmpty {
                EmptyStateView(
                    icon: "map",
                    title: "Loading Galaxy Map",
                    message: "Fetching system data..."
                )
            } else {
                GeometryReader { geometry in
                    let size = geometry.size
                    Canvas { context, canvasSize in
                        drawConnections(context: context, size: canvasSize)
                        drawSystems(context: context, size: canvasSize)
                    }
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                viewModel.scale = max(0.5, min(10, value.magnification))
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.offset = value.translation
                            }
                    )
                    .onTapGesture { location in
                        handleTap(at: location, in: size)
                    }
                }
            }

            // Top-left: current system label
            VStack {
                HStack {
                    if let current = viewModel.currentSystem {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text(current)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(8)

            // Top-right: controls
            VStack {
                HStack {
                    Spacer()
                    MapControlsView(viewModel: viewModel)
                }
                Spacer()
            }
            .padding(8)

            // Bottom-left: empire legend
            VStack {
                Spacer()
                HStack {
                    empireLegend
                    Spacer()
                }
            }
            .padding(8)
        }
    }

    private var empireLegend: some View {
        HStack(spacing: 10) {
            legendDot(color: .purple, label: "Nebula")
            legendDot(color: .yellow, label: "Solar")
            legendDot(color: .cyan, label: "Void")
            legendDot(color: .green, label: "Terra")
            legendDot(color: .gray, label: "Neutral")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func drawConnections(context: GraphicsContext, size: CGSize) {
        let systemMap = Dictionary(uniqueKeysWithValues: viewModel.systems.map { ($0.id, $0) })

        for system in viewModel.systems {
            let from = viewModel.normalizedPosition(for: system, in: size)
            for connId in system.connections ?? [] {
                guard let target = systemMap[connId] else { continue }
                // Only draw each connection once
                guard system.id < target.id else { continue }
                let to = viewModel.normalizedPosition(for: target, in: size)

                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                context.stroke(
                    path,
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 0.5
                )
            }
        }
    }

    private func drawSystems(context: GraphicsContext, size: CGSize) {
        for system in viewModel.systems {
            let pos = viewModel.normalizedPosition(for: system, in: size)
            let isCurrent = viewModel.isCurrent(system)
            let isVisited = viewModel.isVisited(system)
            let isSelected = system.id == viewModel.selectedSystemId

            let radius: CGFloat = isCurrent ? 5 : (isSelected ? 4 : 3)
            let color = empireSwiftColor(viewModel.empireColor(for: system))
            let opacity: Double = isCurrent ? 1.0 : (isVisited ? 0.9 : 0.3)

            let rect = CGRect(
                x: pos.x - radius,
                y: pos.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            if isCurrent {
                let glowRect = rect.insetBy(dx: -4, dy: -4)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(color.opacity(0.3))
                )
            }

            context.fill(
                Circle().path(in: rect),
                with: .color(color.opacity(opacity))
            )

            if isSelected {
                context.stroke(
                    Circle().path(in: rect.insetBy(dx: -2, dy: -2)),
                    with: .color(.white),
                    lineWidth: 1
                )
            }
        }
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        let adjustedLocation = CGPoint(
            x: (location.x - viewModel.offset.width) / viewModel.scale,
            y: (location.y - viewModel.offset.height) / viewModel.scale
        )

        var closest: MapSystem?
        var closestDist: CGFloat = .infinity

        for system in viewModel.systems {
            let pos = viewModel.normalizedPosition(for: system, in: size)
            let dist = hypot(pos.x - adjustedLocation.x, pos.y - adjustedLocation.y)
            if dist < closestDist && dist < 20 {
                closestDist = dist
                closest = system
            }
        }

        viewModel.selectSystem(closest?.id)
    }

    private func empireSwiftColor(_ empire: String) -> Color {
        switch empire.lowercased() {
        case "nebula": return .purple
        case "solar": return .yellow
        case "void": return .cyan
        case "terra": return .green
        default: return .gray
        }
    }
}
