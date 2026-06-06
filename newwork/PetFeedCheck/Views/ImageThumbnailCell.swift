import SwiftUI
import PhotosUI

struct ImageThumbnailCell: View {
    let imageData: Data
    let onDelete: () -> Void
    let onTap: () -> Void

    @State private var showDeleteButton = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: imageData) {
                PhotosPicker(
                    selection: Binding(
                        get: { [] },
                        set: { _ in onTap() }
                    ),
                    matching: .images
                ) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.red.opacity(0.8)))
                        .padding(4)
                }
                .opacity(showDeleteButton ? 1 : 0)
                .onAppear { withAnimation(.easeOut(duration: 0.2)) { showDeleteButton = true } }
            }
        }
    }
}

#Preview {
    let sample = UIImage(systemName: "photo")!.pngData()!
    return ImageThumbnailCell(
        imageData: sample,
        onDelete: {},
        onTap: {}
    )
    .frame(width: 100, height: 100)
}
