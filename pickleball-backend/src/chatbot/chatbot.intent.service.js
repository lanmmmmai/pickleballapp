function detectIntent(question = "") {
  const q = question.toLowerCase();

  if (/voucher|khuyến mãi|ưu đãi|mã giảm/.test(q)) return "LIVE_VOUCHER";
  if (/video|clip|hướng dẫn/.test(q)) return "LIVE_VIDEO";
  if (/hlv|huấn luyện viên|coach|lớp học/.test(q)) return "LIVE_COACH";
  if (/booking của tôi|lịch đặt của tôi|đơn đặt của tôi/.test(q)) return "LIVE_MY_BOOKING";
  if (/còn sân|sân nào|slot|khung giờ|giá sân|mở cửa|đóng cửa/.test(q)) return "HYBRID_COURT";
  if (/pickleball là gì|cách đặt sân|quy trình|giới thiệu|dịch vụ|usp/.test(q)) return "KB_ONLY";

  return "HYBRID_GENERAL";
}

module.exports = { detectIntent };