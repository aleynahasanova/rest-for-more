import 'package:flutter/material.dart';

import '../models/blockable_app.dart';

abstract final class MockBlockableApps {
  static const all = <BlockableApp>[
    BlockableApp(
      id: 'instagram',
      name: 'Instagram',
      packageName: 'com.instagram.android',
      icon: Icons.camera_alt_outlined,
      iconColor: Color(0xFFE1306C),
    ),
    BlockableApp(
      id: 'tiktok',
      name: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      icon: Icons.music_note_outlined,
      iconColor: Color(0xFF010101),
    ),
    BlockableApp(
      id: 'youtube',
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      icon: Icons.play_circle_outline,
      iconColor: Color(0xFFFF0000),
    ),
    BlockableApp(
      id: 'snapchat',
      name: 'Snapchat',
      packageName: 'com.snapchat.android',
      icon: Icons.photo_camera_outlined,
      iconColor: Color(0xFFFFFC00),
    ),
    BlockableApp(
      id: 'facebook',
      name: 'Facebook',
      packageName: 'com.facebook.katana',
      icon: Icons.facebook_outlined,
      iconColor: Color(0xFF1877F2),
    ),
    BlockableApp(
      id: 'x',
      name: 'X (Twitter)',
      packageName: 'com.twitter.android',
      icon: Icons.tag,
      iconColor: Color(0xFF000000),
    ),
  ];

  static const defaultSelectedIds = {
    'instagram',
    'tiktok',
    'youtube',
  };
}