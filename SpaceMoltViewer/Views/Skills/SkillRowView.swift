import SwiftUI

struct SkillRowView: View {
    let skill: PlayerSkill

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(skill.name)
                    .font(.subheadline.bold())
                Text(skill.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())

                Spacer()

                Text("Level \(skill.level)/\(skill.maxLevel)")
                    .font(.subheadline.monospacedDigit())
            }

            ProgressView(value: skill.progress)
                .tint(progressColor)

            HStack {
                Text("\(skill.currentXp.formatted()) / \(skill.nextLevelXp.formatted()) XP")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(skill.progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private var progressColor: Color {
        if skill.level >= skill.maxLevel { return .green }
        if skill.progress > 0.75 { return .blue }
        return .accentColor
    }
}
