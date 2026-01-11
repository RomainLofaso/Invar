//
//  ScreenRecordingPermissionView.swift
//  Invar
//

import InvarCore
import SwiftUI

struct ScreenRecordingPermissionView: View {
    @ObservedObject var viewModel: ScreenRecordingPermissionViewModel

    private let bullets = [
        ScreenRecordingPermissionCopy.bullet1,
        ScreenRecordingPermissionCopy.bullet2,
        ScreenRecordingPermissionCopy.bullet3,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image("PermissionIcon")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                Text("Invar")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text(ScreenRecordingPermissionCopy.primary)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 22)

            Text(ScreenRecordingPermissionCopy.secondary)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            Text("Your privacy")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text(bullet)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)

            HStack(spacing: 8) {
                Spacer()
                Button("Continue", action: viewModel.requestPermission)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 500)
        // The view is hosted in a dedicated AppKit window, so inline UI is simpler than a sheet.
    }
}
