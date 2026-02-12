import 'package:flutter/material.dart';

ImageProvider<Object>? safeNetworkImage(String? rawUrl) {
  final url = rawUrl?.trim();
  if (url == null || url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  final isValidNetworkUrl =
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;

  if (!isValidNetworkUrl) return null;
  return NetworkImage(url);
}
