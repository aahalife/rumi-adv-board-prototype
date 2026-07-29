import SwiftUI

/// Documents (§4.4.10) — the paper that runs alongside care, captured and kept
/// in one private place. Extraction is always shown for confirmation before it
/// touches the record; low-confidence fields are flagged, never silently
/// trusted (DOC-4). Provenance ("From your scan") stays visible.
struct DocumentsView: View {
    @Environment(AppModel.self) private var model
    @State private var adding = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Documents")
                        .font(NudgeType.serif(28))
                        .foregroundStyle(Theme.ink)
                    Text("Cards, results, forms — kept private and easy to find.")
                        .font(NudgeType.rounded(13))
                        .foregroundStyle(Theme.inkMuted)
                }
                .padding(.top, 8)

                Button {
                    Haptics.tick()
                    adding = true
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 15, weight: .light))
                        Text("Add a document")
                            .font(NudgeType.rounded(14.5, .semibold))
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .light))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
                }
                .buttonStyle(NudgeButtonStyle())

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(model.careDocuments) { document in
                        NavigationLink(value: DocumentRoute(id: document.id)) {
                            documentCard(document)
                        }
                        .buttonStyle(NudgeButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .navigationDestination(for: DocumentRoute.self) { route in
            ZStack {
                LivingGradientView()
                DocumentDetailView(documentID: route.id)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $adding) {
            AddDocumentSheet { title, type in
                model.addDocument(CareDocument(title: title, type: type,
                                               capturedAt: .now, source: "Added by you"))
                adding = false
            }
            .presentationDetents([.height(440)])
            .presentationBackground(Theme.base)
        }
    }

    private func documentCard(_ document: CareDocument) -> some View {
        OrganicSurface(radius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Color(.secondarySystemBackground).opacity(0.0)
                    .frame(height: 84)
                    .overlay {
                        if let bundled = document.bundledImage, UIImage(named: bundled) != nil {
                            Image(bundled).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        } else if let filename = document.imageFilename,
                                  let image = UIImage(contentsOfFile: URL.documentsDirectory.appendingPathComponent(filename).path) {
                            Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        } else {
                            ZStack {
                                LinearGradient(colors: [Theme.sky.opacity(0.18), Theme.gold.opacity(0.14)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                Image(systemName: document.type.glyph)
                                    .font(.system(size: 30, weight: .ultraLight))
                                    .foregroundStyle(Theme.ink.opacity(0.55))
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(NudgeType.serif(15))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Text(document.type.rawValue)
                            .font(NudgeType.rounded(11))
                            .foregroundStyle(Theme.inkMuted)
                        if !document.confirmed {
                            Circle().fill(Theme.attention).frame(width: 5, height: 5)
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}

/// Local route so the documents grid can push a detail without widening the
/// hub's CareDestination surface.
struct DocumentRoute: Hashable { let id: UUID }

// MARK: - Detail

struct DocumentDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let documentID: UUID
    @State private var removing = false

    private var document: CareDocument? { model.careDocuments.first { $0.id == documentID } }

    var body: some View {
        Group {
            if let document {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        preview(document)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(document.title)
                                .font(NudgeType.serif(26))
                                .foregroundStyle(Theme.ink)
                            HStack(spacing: 8) {
                                Label(document.type.rawValue, systemImage: document.type.glyph)
                                Text("·")
                                Text(document.capturedAt.formatted(.dateTime.month(.wide).day().year()))
                            }
                            .font(NudgeType.rounded(12.5))
                            .foregroundStyle(Theme.inkMuted)
                        }

                        if !document.fields.isEmpty { fieldsCard(document) }

                        if !document.confirmed && !document.fields.isEmpty {
                            Button {
                                model.confirmDocument(document.id)
                            } label: {
                                Text("These details look right")
                                    .font(NudgeType.rounded(15, .semibold))
                                    .foregroundStyle(Theme.base)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Theme.ink, in: .capsule)
                            }
                            .buttonStyle(NudgeButtonStyle())
                        } else if document.confirmed {
                            Label("Confirmed — these details are part of your record", systemImage: "checkmark.seal.fill")
                                .font(NudgeType.rounded(13, .semibold))
                                .foregroundStyle(Theme.life)
                        }

                        ProvenanceChip(text: document.source)

                        Button(role: .destructive) {
                            removing = true
                        } label: {
                            Text("Remove this document")
                                .font(NudgeType.rounded(13.5, .medium))
                                .foregroundStyle(Theme.warm)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                        }
                        .buttonStyle(NudgeButtonStyle())
                        .confirmationDialog("Remove this document? This only deletes your private copy in Rumi.",
                                            isPresented: $removing, titleVisibility: .visible) {
                            Button("Remove", role: .destructive) {
                                model.removeDocument(document.id)
                                dismiss()
                            }
                            Button("Keep it", role: .cancel) {}
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            } else {
                ContentUnavailableView("This document isn't available", systemImage: "doc")
            }
        }
    }

    private func preview(_ document: CareDocument) -> some View {
        Color(.secondarySystemBackground).opacity(0.0)
            .frame(height: 200)
            .overlay {
                if let bundled = document.bundledImage, UIImage(named: bundled) != nil {
                    Image(bundled).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                } else if let filename = document.imageFilename,
                          let image = UIImage(contentsOfFile: URL.documentsDirectory.appendingPathComponent(filename).path) {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                } else {
                    ZStack {
                        LinearGradient(colors: [Theme.sky.opacity(0.2), Theme.gold.opacity(0.16)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        VStack(spacing: 8) {
                            Image(systemName: document.type.glyph)
                                .font(.system(size: 44, weight: .ultraLight))
                                .foregroundStyle(Theme.ink.opacity(0.5))
                            if document.pageCount > 1 {
                                Text("\(document.pageCount) pages")
                                    .font(NudgeType.rounded(11, .medium))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                        }
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
            )
    }

    private func fieldsCard(_ document: CareDocument) -> some View {
        OrganicSurface(radius: 26) {
            VStack(alignment: .leading, spacing: 12) {
                Kicker(text: document.confirmed ? "Details" : "Pulled from your scan — check these", color: Theme.sky)
                ForEach(document.fields) { field in
                    HStack(alignment: .top) {
                        Text(field.label)
                            .font(NudgeType.rounded(13))
                            .foregroundStyle(Theme.inkMuted)
                        Spacer(minLength: 12)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(field.value)
                                .font(NudgeType.rounded(13.5, .medium))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.trailing)
                            if field.lowConfidence {
                                Text("double-check")
                                    .font(NudgeType.rounded(10, .medium))
                                    .foregroundStyle(Theme.attention)
                            }
                        }
                    }
                    if field.id != document.fields.last?.id {
                        Divider().overlay(Theme.edge.opacity(0.4))
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Add

/// A calm manual entry. On a real device this is where a scan auto-fills the
/// details; here it's an honest, typed record.
struct AddDocumentSheet: View {
    let onAdd: (String, DocumentType) -> Void
    @State private var title = ""
    @State private var type: DocumentType = .other
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add a document")
                .font(NudgeType.serif(22))
                .foregroundStyle(Theme.ink)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Kicker(text: "What is it?", color: Theme.sky)
                TextField("Insurance card, lab result…", text: $title)
                    .font(NudgeType.rounded(15))
                    .foregroundStyle(Theme.ink)
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Kicker(text: "Type", color: Theme.gold)
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(DocumentType.allCases) { option in
                            let selected = type == option
                            Button {
                                Haptics.tick()
                                type = option
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: option.glyph).font(.system(size: 11, weight: .medium))
                                    Text(option.rawValue).font(NudgeType.rounded(12.5, .medium))
                                }
                                .foregroundStyle(selected ? Theme.base : Theme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selected ? Theme.ink : Color.clear, in: .capsule)
                                .overlay(Capsule().strokeBorder(Theme.edge.opacity(selected ? 0 : 0.7), lineWidth: 0.8))
                            }
                            .buttonStyle(NudgeButtonStyle())
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            Button {
                let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                onAdd(trimmed.isEmpty ? type.rawValue : trimmed, type)
            } label: {
                Text("Save to documents")
                    .font(NudgeType.rounded(15, .semibold))
                    .foregroundStyle(Theme.base)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.ink, in: .capsule)
            }
            .buttonStyle(NudgeButtonStyle())

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .onAppear { focused = true }
    }
}
