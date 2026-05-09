import Foundation

enum LessonStatus: String, Codable, CaseIterable {
    case scheduled = "已预约"
    case completed = "已完成"
    case cancelled = "已取消"
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "现金"
    case wechat = "微信"
    case alipay = "支付宝"
    case bankTransfer = "银行转账"
    case other = "其他"
}

enum ScheduleType: String, Codable, CaseIterable {
    case individual = "一对一"
    case group = "集体课"
}

enum ExceptionType: String, Codable, CaseIterable {
    case rescheduled = "临时调课"
    case cancelled = "取消一次"
}
