import SwiftUI

struct GalaxyMapView: View {
    @Bindable var viewModel: MapViewModel

    var body: some View {
        ZStack {
            // Dark space background
            Color.black
                .ignoresSafeArea()

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

    // MARK: - Empire Legend

    private var empireLegend: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("EMPIRES")
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.8))

            legendDot(color: EmpireTheme.color(for: "solarian"), label: "Solarian")
            legendDot(color: EmpireTheme.color(for: "voidborn"), label: "Voidborn")
            legendDot(color: EmpireTheme.color(for: "crimson"), label: "Crimson")
            legendDot(color: EmpireTheme.color(for: "nebula"), label: "Nebula")
            legendDot(color: EmpireTheme.color(for: "outerrim"), label: "Outer Rim")
            legendDot(color: EmpireTheme.color(for: "neutral"), label: "Neutral")
            legendDot(color: EmpireTheme.color(for: "pirate"), label: "Pirate Stronghold")
        }
        .padding(10)
        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Drawing

    private func drawConnections(context: GraphicsContext, size: CGSize) {
        let systemMap = Dictionary(uniqueKeysWithValues: viewModel.systems.map { ($0.id, $0) })

        for system in viewModel.systems {
            let from = viewModel.normalizedPosition(for: system, in: size)
            for connId in system.connections ?? [] {
                guard let target = systemMap[connId] else { continue }
                guard system.id < target.id else { continue }
                let to = viewModel.normalizedPosition(for: target, in: size)

                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                context.stroke(
                    path,
                    with: .color(.gray.opacity(0.25)),
                    lineWidth: 0.5
                )
            }
        }
    }

    private func drawSystems(context: GraphicsContext, size: CGSize) {
        // Draw non-special systems first, then empire, then capitals on top
        let sorted = viewModel.systems.sorted { a, b in
            let aOrder = drawOrder(a)
            let bOrder = drawOrder(b)
            return aOrder < bOrder
        }

        for system in sorted {
            let pos = viewModel.normalizedPosition(for: system, in: size)
            let isCurrent = viewModel.isCurrent(system)
            let isVisited = viewModel.isVisited(system)
            let isSelected = system.id == viewModel.selectedSystemId
            let isCapital = system.isHome == true
            let isStronghold = system.isStronghold == true
            let empireKey = viewModel.empireColor(for: system)
            let color = EmpireTheme.color(for: empireKey)

            let baseRadius: CGFloat = {
                if isCapital { return 7 }
                if isCurrent { return 5 }
                if isStronghold { return 4 }
                if isSelected { return 4 }
                if system.empire != nil { return 3.5 }
                return 2.5
            }()

            let opacity: Double = {
                if isCapital || isCurrent || isStronghold { return 1.0 }
                if system.empire != nil { return 0.9 }
                if isVisited { return 0.6 }
                return 0.35
            }()

            let rect = CGRect(
                x: pos.x - baseRadius,
                y: pos.y - baseRadius,
                width: baseRadius * 2,
                height: baseRadius * 2
            )

            // Current system glow
            if isCurrent {
                let glowRect = rect.insetBy(dx: -5, dy: -5)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(.green.opacity(0.3))
                )
            }

            // Capital outer ring glow
            if isCapital {
                let outerGlow = rect.insetBy(dx: -6, dy: -6)
                context.fill(
                    Circle().path(in: outerGlow),
                    with: .color(color.opacity(0.2))
                )
                let ring = rect.insetBy(dx: -4, dy: -4)
                context.stroke(
                    Circle().path(in: ring),
                    with: .color(color.opacity(0.6)),
                    lineWidth: 1.5
                )
            }

            // Pirate stronghold glow
            if isStronghold {
                let glowRect = rect.insetBy(dx: -4, dy: -4)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(color.opacity(0.25))
                )
            }

            // Main dot
            context.fill(
                Circle().path(in: rect),
                with: .color(color.opacity(opacity))
            )

            // Selection ring
            if isSelected {
                context.stroke(
                    Circle().path(in: rect.insetBy(dx: -2, dy: -2)),
                    with: .color(.white),
                    lineWidth: 1.5
                )
            }

            // Capital name label
            if isCapital {
                let text = Text(system.name)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                context.draw(
                    context.resolve(text),
                    at: CGPoint(x: pos.x, y: pos.y + baseRadius + 8),
                    anchor: .top
                )
            }
        }
    }

    /// Controls z-ordering: higher = drawn on top
    private func drawOrder(_ system: MapSystem) -> Int {
        if system.isHome == true { return 3 }
        if viewModel.isCurrent(system) { return 2 }
        if system.isStronghold == true { return 1 }
        if system.empire != nil { return 1 }
        return 0
    }

    // MARK: - Tap Handling

    private func handleTap(at location: CGPoint, in size: CGSize) {
        // scaleEffect scales around center, so we must account for that anchor
        let centerX = size.width / 2
        let centerY = size.height / 2
        let adjustedLocation = CGPoint(
            x: (location.x - viewModel.offset.width - centerX) / viewModel.scale + centerX,
            y: (location.y - viewModel.offset.height - centerY) / viewModel.scale + centerY
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


}
