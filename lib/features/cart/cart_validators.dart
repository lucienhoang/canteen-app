String? validatePickupTime(DateTime picked, DateTime now) {
  // Kiểm tra có khác ngày không
  if (picked.year != now.year || picked.month != now.month || picked.day != now.day) {
    return 'Chỉ được chọn giờ lấy trong ngày hôm nay.';
  }

  // Kiểm tra thời gian tối thiểu 10 phút
  final difference = picked.difference(now).inMinutes;
  if (difference < 10) {
    return 'Giờ lấy phải cách thời điểm đặt ít nhất 10 phút.';
  }

  return null; // Hợp lệ
}