import Foundation
import SwiftUI

struct SkillSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct BranchBriefChangedFile: Identifiable {
    let id = UUID()
    let path: String
    let status: String
}

struct BranchBriefSnapshot {
    let branch: String
    let upstream: String
    let baseRef: String
    let baseRefReason: String
    let ahead: Int
    let behind: Int
    let stagedCount: Int
    let unstagedCount: Int
    let untrackedCount: Int
    let touchedAreas: [String]
    let changedFiles: [BranchBriefChangedFile]
    let changedFileCount: Int
    let recentCommits: [String]
    let nextAction: String
}

struct BranchBriefBarDetailView: View {
    let snapshot: BranchBriefSnapshot
    let sections: [SkillSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            snapshotCard
            sectionsCard
            commitsCard
            actionCard
        }
    }

    private var snapshotCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(snapshot.branch, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.headline)
                    .foregroundStyle(BranchBriefBarTheme.textPrimary)
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(snapshot.upstream)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BranchBriefBarTheme.textSecondary)
                    Text("Base: \(snapshot.baseRef)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(BranchBriefBarTheme.textSecondary.opacity(0.8))
                    Text(snapshot.baseRefReason)
                        .font(.caption2)
                        .foregroundStyle(BranchBriefBarTheme.textSecondary.opacity(0.65))
                }
            }

            HStack(spacing: 10) {
                MetricPill(label: "Ahead", value: snapshot.ahead)
                MetricPill(label: "Behind", value: snapshot.behind)
                MetricPill(label: "Staged", value: snapshot.stagedCount)
                MetricPill(label: "Dirty", value: snapshot.unstagedCount + snapshot.untrackedCount)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Touched areas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BranchBriefBarTheme.textSecondary)
                Text(snapshot.touchedAreas.joined(separator: "  ·  "))
                    .font(.subheadline)
                    .foregroundStyle(BranchBriefBarTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Changed files")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BranchBriefBarTheme.textSecondary)
                    if snapshot.changedFileCount > snapshot.changedFiles.count {
                        Text("+\(snapshot.changedFileCount - snapshot.changedFiles.count) more")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(BranchBriefBarTheme.textSecondary.opacity(0.8))
                    }
                }

                ForEach(snapshot.changedFiles) { file in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        FileStatusPill(text: file.status)
                        Text(file.path)
                            .font(.caption.monospaced())
                            .foregroundStyle(BranchBriefBarTheme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
        .padding(14)
        .background(BranchBriefBarTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BranchBriefBarTheme.border, lineWidth: 1)
        )
    }

    private var sectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(BranchBriefBarTheme.textPrimary)
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(BranchBriefBarTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(BranchBriefBarTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BranchBriefBarTheme.border, lineWidth: 1)
        )
    }

    private var commitsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent commits")
                .font(.headline)
                .foregroundStyle(BranchBriefBarTheme.textPrimary)

            ForEach(snapshot.recentCommits, id: \.self) { commit in
                Label(commit, systemImage: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundStyle(BranchBriefBarTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(BranchBriefBarTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BranchBriefBarTheme.border, lineWidth: 1)
        )
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next action")
                .font(.headline)
                .foregroundStyle(BranchBriefBarTheme.textPrimary)
            Text(snapshot.nextAction)
                .font(.subheadline)
                .foregroundStyle(BranchBriefBarTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(BranchBriefBarTheme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BranchBriefBarTheme.accent.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct MetricPill: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(BranchBriefBarTheme.textSecondary)
            Text("\(value)")
                .font(.caption.weight(.bold))
                .foregroundStyle(BranchBriefBarTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FileStatusPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(BranchBriefBarTheme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(BranchBriefBarTheme.accent.opacity(0.18), in: Capsule(style: .continuous))
    }
}

extension BranchBriefSnapshot {
    static let preview = BranchBriefSnapshot(
        branch: "feature/branch-brief-bar",
        upstream: "origin/feature/branch-brief-bar",
        baseRef: "origin/main",
        baseRefReason: "remote default branch",
        ahead: 3,
        behind: 0,
        stagedCount: 1,
        unstagedCount: 2,
        untrackedCount: 1,
        touchedAreas: ["skills/branch-brief-bar", "README.md", "collections/productivity-and-workflow.txt"],
        changedFiles: [
            BranchBriefChangedFile(path: "skills/branch-brief-bar/scripts/branch_brief.py", status: "committed + staged"),
            BranchBriefChangedFile(path: "skills/branch-brief-bar/prototype/SkillDetailView.swift", status: "staged + unstaged"),
            BranchBriefChangedFile(path: "README.md", status: "unstaged")
        ],
        changedFileCount: 5,
        recentCommits: [
            "a41bc92 Add local branch brief helper",
            "73f4ab8 Refresh SwiftUI prototype",
            "5982e11 Tighten package metadata"
        ],
        nextAction: "Run checks, commit the remaining working tree changes, and paste the markdown brief into the PR update."
    )
}

extension BranchBriefBarDetailView {
    static var previewSections: [SkillSection] {
        [
            SkillSection(
                title: "Branch snapshot",
                body: "Show branch, compare base, compare-base reason, upstream distance, and working tree counts as one top card instead of making the user reconstruct the state from multiple git commands."
            ),
            SkillSection(
                title: "Handoff brief",
                body: "Surface touched areas, status-aware changed-file previews, recent commits, and the next action in a summary that is already shaped for review chat, standup notes, or a PR update."
            ),
            SkillSection(
                title: "Review flow",
                body: "Keep copy brief, open repo, reveal diff, and blocked-state actions together so the jump from shell work to review handoff feels deliberate and calm even when the remote upstream is only the same feature branch."
            )
        ]
    }
}
