import SwiftUI

struct PaymentRowView: View {
    let payment: Payment

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.date.dateString())
                    .font(.subheadline.bold())

                if let gc = payment.groupClass {
                    Text(gc.name)
                        .font(.caption)
                        .foregroundColor(.purple)
                }

                Text(payment.paymentMethod.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 70, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("¥\(String(format: "%.0f", payment.amount))")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text("\(payment.lessonCount)课时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("有效期: \(payment.validityStart.dateString()) - \(payment.validityEnd.dateString())")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let notes = payment.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}
