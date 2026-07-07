//
//  SettingsView.swift
//  NaiwaSeeYou
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var showShareSheet = false

    // TODO: 换成正式上架的 App Store ID
    private let appStoreID = "0000000000"

    // TODO: 换成正式链接
    private let faqURL = "https://example.com/faq"
    private let privacyURL = "https://example.com/privacy"
    private let termsURL = "https://example.com/terms"

    private var reviewURL: String {
        "https://apps.apple.com/app/id\(appStoreID)?action=write-review"
    }

    private var shareURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    settingsRow(emoji: "🤩", title: "给个五星好评") {
                        openURL(reviewURL)
                    }
                    settingsRow(emoji: "📤", title: "分享给朋友") {
                        showShareSheet = true
                    }

                    divider

                    settingsRow(emoji: "🤔", title: "常见疑问解答") {
                        openURL(faqURL)
                    }

                    divider

                    settingsRow(emoji: "🔒", title: "隐私政策") {
                        openURL(privacyURL)
                    }
                    settingsRow(emoji: "📄", title: "服务条款") {
                        openURL(termsURL)
                    }
                }
                .padding(.top, 12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            ToolbarItem(placement: .principal) {
                Text("设置")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareURL])
        }
    }

    // MARK: - Row

    private func settingsRow(emoji: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black.opacity(0.4))
            }
            .padding(.horizontal, hSizeClass == .regular ? 24 : 32)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.12))
            .frame(height: 0.5)
            .padding(.horizontal, hSizeClass == .regular ? 24 : 32)
            .padding(.vertical, 4)
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
