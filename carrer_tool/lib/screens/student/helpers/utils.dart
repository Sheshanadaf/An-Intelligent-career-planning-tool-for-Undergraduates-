String getFullImageUrl(String? imageUrl) {
  const backendBaseUrl = 'http://10.0.2.2:4000';
  if (imageUrl == null || imageUrl.isEmpty) return "";
  if (imageUrl.startsWith('http')) return imageUrl;
  return '$backendBaseUrl/$imageUrl';
}
