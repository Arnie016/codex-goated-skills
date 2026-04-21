import SwiftUI

struct ReplyQueueBarMenuBarView: View {
    let snapshot: ReplyQueueSnapshot
    @State private var selectedBucket: ReplyQueueBucket = .urgent

    init(snapshot: ReplyQueueSnapshot = .preview) {
        self.snapshot = snapshot
    }

    private var visibleItems: [ReplyQueueItem] {
        snapshot.items(for: selectedBucket)
    }

    private var focusedItem: ReplyQueueItem? {
        visibleItems.first ?? snapshot.nextItem
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                metricsRow
                bucketPicker
                queueSection
                if let focusedItem {
                    DraftCard(item: focusedItem)
                }
                ReplyQueueBarDetailView(sections: ReplyQueueBarDetailView.previewSections)
                actionRow
            }
            .padding(16)
        }
        .frame(width: 372, height: 640)
        .background(ReplyQueueBarTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ReplyQueueBarTheme.accent)
                Image(systemName: "ellipsis.bubble.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Reply Queue Bar")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ReplyQueueBarTheme.textPrimary)
                Text("Keep the next copied comment, draft, and archive move visible from the menu bar.")
                    .font(.subheadline)
                    .foregroundStyle(ReplyQueueBarTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 10) {
            ForEach(ReplyQueueBucket.allCases) { bucket in
                MetricTile(
                    title: bucket.title,
                    value: snapshot.count(for: bucket),
                    tint: bucket.tint
                )
            }
        }
    }

    private var bucketPicker: some View {
        HStack(spacing: 8) {
            ForEach(ReplyQueueBucket.allCases) { bucket in
                BucketChip(
                    bucket: bucket,
                    isSelected: selectedBucket == bucket
                ) {
                    selectedBucket = bucket
                }
            }
        }
    }

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedBucket.sectionTitle)
                    .font(.headline)
                    .foregroundStyle(ReplyQueueBarTheme.textPrimary)
                Spacer(minLength: 0)
                Text("\(visibleItems.count) items")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ReplyQueueBarTheme.textSecondary)
            }

            if visibleItems.isEmpty {
                EmptyQueueCard(bucket: selectedBucket)
            } else {
                ForEach(visibleItems.prefix(3)) { item in
                    QueueItemCard(item: item)
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button("Capture Clipboard") { }
                .buttonStyle(.borderedProminent)
            Button("Copy Draft") { }
                .buttonStyle(.bordered)
            Button("Archive") { }
                .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
        .tint(ReplyQueueBarTheme.accent)
    }
}

private struct MetricTile: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(ReplyQueueBarTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(ReplyQueueBarTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ReplyQueueBarTheme.border, lineWidth: 1)
        )
    }
}

private struct BucketChip: View {
    let bucket: ReplyQueueBucket
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: bucket.symbol)
                    .font(.caption.weight(.semibold))
                Text(bucket.title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : ReplyQueueBarTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? bucket.tint : ReplyQueueBarTheme.panel)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ReplyQueueBarTheme.border, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct QueueItemCard: View {
    let item: ReplyQueueItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.source)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ReplyQueueBarTheme.textPrimary)
                    Text(item.receivedLabel)
                        .font(.caption)
                        .foregroundStyle(ReplyQueueBarTheme.textSecondary)
                }
                Spacer(minLength: 0)
                TagPill(text: item.bucket.title)
            }

            Text(item.text)
                .font(.subheadline)
                .foregroundStyle(ReplyQueueBarTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                TagPill(text: item.urgencyLabel)
                ForEach(item.tags, id: \.self) { tag in
                    TagPill(text: "#\(tag)")
                }
            }
        }
        .padding(12)
        .background(ReplyQueueBarTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ReplyQueueBarTheme.border, lineWidth: 1)
        )
    }
}

private struct DraftCard: View {
    let item: ReplyQueueItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ready draft")
                    .font(.headline)
                    .foregroundStyle(ReplyQueueBarTheme.textPrimary)
                Spacer(minLength: 0)
                Text(item.source)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ReplyQueueBarTheme.textSecondary)
            }

            Text(item.draft)
                .font(.subheadline)
                .foregroundStyle(ReplyQueueBarTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ActionPill(label: "Copy draft", systemImage: "doc.on.doc")
                ActionPill(label: "Send forward", systemImage: "arrow.up.right")
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .background(ReplyQueueBarTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ReplyQueueBarTheme.border, lineWidth: 1)
        )
    }
}

private struct EmptyQueueCard: View {
    let bucket: ReplyQueueBucket

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing in \(bucket.title.lowercased()) yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ReplyQueueBarTheme.textPrimary)
            Text(bucket.emptyState)
                .font(.caption)
                .foregroundStyle(ReplyQueueBarTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(ReplyQueueBarTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ReplyQueueBarTheme.border, lineWidth: 1)
        )
    }
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ReplyQueueBarTheme.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.white.opacity(0.06), in: Capsule(style: .continuous))
    }
}

private struct ActionPill: View {
    let label: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(label)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(ReplyQueueBarTheme.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(ReplyQueueBarTheme.accent.opacity(0.18), in: Capsule(style: .continuous))
    }
}
