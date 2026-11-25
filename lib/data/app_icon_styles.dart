import 'package:flutter/material.dart';

class AppIconStyle {
  const AppIconStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// Material outlined badges in the same style as TikTok / YouTube / Instagram.
abstract final class AppIconStyles {
  static const _palette = [
    Color(0xFFE1306C),
    Color(0xFF1877F2),
    Color(0xFFFF0000),
    Color(0xFF010101),
    Color(0xFF7B563D),
    Color(0xFF1DB954),
    Color(0xFF5865F2),
    Color(0xFFFF9900),
  ];

  static const _packages = <String, AppIconStyle>{
    'com.instagram.android': AppIconStyle(
      Icons.camera_alt_outlined,
      Color(0xFFE1306C),
    ),
    'com.instagram.barcelona': AppIconStyle(
      Icons.alternate_email,
      Color(0xFF000000),
    ),
    'com.zhiliaoapp.musically': AppIconStyle(
      Icons.music_note_outlined,
      Color(0xFF010101),
    ),
    'com.ss.android.ugc.trill': AppIconStyle(
      Icons.music_note_outlined,
      Color(0xFF010101),
    ),
    'com.google.android.youtube': AppIconStyle(
      Icons.play_circle_outline,
      Color(0xFFFF0000),
    ),
    'com.google.android.apps.youtube.music': AppIconStyle(
      Icons.library_music_outlined,
      Color(0xFFFF0000),
    ),
    'com.google.android.apps.youtube.kids': AppIconStyle(
      Icons.play_circle_outline,
      Color(0xFFFF0000),
    ),
    'com.snapchat.android': AppIconStyle(
      Icons.photo_camera_outlined,
      Color(0xFFC7B800),
    ),
    'com.facebook.katana': AppIconStyle(
      Icons.facebook_outlined,
      Color(0xFF1877F2),
    ),
    'com.facebook.lite': AppIconStyle(
      Icons.facebook_outlined,
      Color(0xFF1877F2),
    ),
    'com.facebook.orca': AppIconStyle(
      Icons.chat_bubble_outline,
      Color(0xFF0084FF),
    ),
    'com.facebook.mlite': AppIconStyle(
      Icons.chat_bubble_outline,
      Color(0xFF0084FF),
    ),
    'com.twitter.android': AppIconStyle(Icons.tag, Color(0xFF000000)),
    'com.reddit.frontpage': AppIconStyle(
      Icons.forum_outlined,
      Color(0xFFFF4500),
    ),
    'com.pinterest': AppIconStyle(
      Icons.push_pin_outlined,
      Color(0xFFE60023),
    ),
    'com.discord': AppIconStyle(
      Icons.headphones_outlined,
      Color(0xFF5865F2),
    ),
    'org.telegram.messenger': AppIconStyle(
      Icons.send_outlined,
      Color(0xFF229ED9),
    ),
    'org.telegram.messenger.web': AppIconStyle(
      Icons.send_outlined,
      Color(0xFF229ED9),
    ),
    'com.whatsapp': AppIconStyle(Icons.chat_outlined, Color(0xFF25D366)),
    'com.whatsapp.w4b': AppIconStyle(Icons.chat_outlined, Color(0xFF25D366)),
    'org.thoughtcrime.securesms': AppIconStyle(
      Icons.lock_outline,
      Color(0xFF3A76F0),
    ),
    'com.viber.voip': AppIconStyle(
      Icons.phone_in_talk_outlined,
      Color(0xFF7360F2),
    ),
    'com.skype.raider': AppIconStyle(
      Icons.video_call_outlined,
      Color(0xFF00AFF0),
    ),
    'jp.naver.line.android': AppIconStyle(
      Icons.chat_bubble_outline,
      Color(0xFF00C300),
    ),
    'com.tencent.mm': AppIconStyle(Icons.chat_outlined, Color(0xFF07C160)),
    'com.linkedin.android': AppIconStyle(
      Icons.work_outline,
      Color(0xFF0A66C2),
    ),
    'com.tumblr': AppIconStyle(Icons.article_outlined, Color(0xFF36465D)),
    'com.bereal.ft': AppIconStyle(
      Icons.camera_alt_outlined,
      Color(0xFF000000),
    ),
    'com.netflix.mediaclient': AppIconStyle(
      Icons.movie_outlined,
      Color(0xFFE50914),
    ),
    'com.disney.disneyplus': AppIconStyle(
      Icons.movie_outlined,
      Color(0xFF113CCF),
    ),
    'com.amazon.avod.thirdpartyclient': AppIconStyle(
      Icons.play_circle_outline,
      Color(0xFF00A8E1),
    ),
    'tv.twitch.android.app': AppIconStyle(
      Icons.videogame_asset_outlined,
      Color(0xFF9146FF),
    ),
    'com.spotify.music': AppIconStyle(
      Icons.library_music_outlined,
      Color(0xFF1DB954),
    ),
    'com.soundcloud.android': AppIconStyle(
      Icons.graphic_eq,
      Color(0xFFFF5500),
    ),
    'com.apple.android.music': AppIconStyle(
      Icons.library_music_outlined,
      Color(0xFFFC3C44),
    ),
    'deezer.android.app': AppIconStyle(
      Icons.library_music_outlined,
      Color(0xFFA238FF),
    ),
    'com.hulu.plus': AppIconStyle(Icons.tv_outlined, Color(0xFF1CE783)),
    'com.plexapp.android': AppIconStyle(Icons.tv_outlined, Color(0xFFE5A00D)),
    'org.videolan.vlc': AppIconStyle(
      Icons.play_circle_outline,
      Color(0xFFFF8800),
    ),
    'com.google.android.gm': AppIconStyle(
      Icons.mail_outline,
      Color(0xFFEA4335),
    ),
    'com.google.android.apps.maps': AppIconStyle(
      Icons.map_outlined,
      Color(0xFF34A853),
    ),
    'com.android.chrome': AppIconStyle(Icons.language, Color(0xFF4285F4)),
    'com.chrome.beta': AppIconStyle(Icons.language, Color(0xFF4285F4)),
    'com.google.android.apps.photos': AppIconStyle(
      Icons.photo_outlined,
      Color(0xFFFABC05),
    ),
    'com.google.android.apps.docs': AppIconStyle(
      Icons.folder_outlined,
      Color(0xFF4285F4),
    ),
    'com.google.android.calendar': AppIconStyle(
      Icons.calendar_today_outlined,
      Color(0xFF4285F4),
    ),
    'com.google.android.apps.tachyon': AppIconStyle(
      Icons.videocam_outlined,
      Color(0xFF00832D),
    ),
    'com.google.android.keep': AppIconStyle(
      Icons.sticky_note_2_outlined,
      Color(0xFFFBBC04),
    ),
    'com.android.vending': AppIconStyle(Icons.shop_outlined, Color(0xFF01875F)),
    'com.google.android.googlequicksearchbox': AppIconStyle(
      Icons.search,
      Color(0xFF4285F4),
    ),
    'com.google.android.apps.translate': AppIconStyle(
      Icons.translate_outlined,
      Color(0xFF4285F4),
    ),
    'com.google.android.contacts': AppIconStyle(
      Icons.contacts_outlined,
      Color(0xFF4285F4),
    ),
    'com.google.android.dialer': AppIconStyle(
      Icons.phone_outlined,
      Color(0xFF34A853),
    ),
    'com.google.android.apps.messaging': AppIconStyle(
      Icons.sms_outlined,
      Color(0xFF1A73E8),
    ),
    'com.google.android.apps.nbu.paisa.user': AppIconStyle(
      Icons.account_balance_wallet_outlined,
      Color(0xFF1A73E8),
    ),
    'org.mozilla.firefox': AppIconStyle(Icons.language, Color(0xFFFF7139)),
    'com.brave.browser': AppIconStyle(Icons.language, Color(0xFFFB542B)),
    'com.opera.browser': AppIconStyle(Icons.language, Color(0xFFFF1B2D)),
    'com.microsoft.emmx': AppIconStyle(Icons.language, Color(0xFF0078D4)),
    'com.microsoft.office.outlook': AppIconStyle(
      Icons.mail_outline,
      Color(0xFF0078D4),
    ),
    'com.microsoft.teams': AppIconStyle(
      Icons.groups_outlined,
      Color(0xFF6264A7),
    ),
    'com.slack': AppIconStyle(Icons.tag, Color(0xFF4A154B)),
    'com.amazon.mShop.android.shopping': AppIconStyle(
      Icons.shopping_bag_outlined,
      Color(0xFFFF9900),
    ),
    'com.einnovation.temu': AppIconStyle(
      Icons.shopping_bag_outlined,
      Color(0xFFFF6A00),
    ),
    'com.zzkko': AppIconStyle(Icons.shopping_bag_outlined, Color(0xFF000000)),
    'com.alibaba.aliexpresshd': AppIconStyle(
      Icons.shopping_bag_outlined,
      Color(0xFFE62E04),
    ),
    'com.ebay.mobile': AppIconStyle(
      Icons.shopping_bag_outlined,
      Color(0xFFE53238),
    ),
    'com.roblox.client': AppIconStyle(
      Icons.sports_esports_outlined,
      Color(0xFFE2231A),
    ),
    'com.mojang.minecraftpe': AppIconStyle(
      Icons.sports_esports_outlined,
      Color(0xFF62B47A),
    ),
    'com.tinder': AppIconStyle(Icons.favorite_border, Color(0xFFFE3C72)),
    'com.bumble.app': AppIconStyle(Icons.favorite_border, Color(0xFFC7A000)),
    'com.airbnb.android': AppIconStyle(Icons.home_outlined, Color(0xFFFF5A5F)),
    'com.ubercab': AppIconStyle(Icons.local_taxi_outlined, Color(0xFF000000)),
    'com.ubercab.eats': AppIconStyle(
      Icons.restaurant_outlined,
      Color(0xFF06C167),
    ),
    'com.paypal.android.p2pmobile': AppIconStyle(
      Icons.payments_outlined,
      Color(0xFF003087),
    ),
    'com.sec.android.app.camera': AppIconStyle(
      Icons.photo_camera_outlined,
      Color(0xFF1428A0),
    ),
    'com.sec.android.gallery3d': AppIconStyle(
      Icons.photo_library_outlined,
      Color(0xFF1428A0),
    ),
    'com.samsung.android.messaging': AppIconStyle(
      Icons.sms_outlined,
      Color(0xFF1428A0),
    ),
    'com.samsung.android.dialer': AppIconStyle(
      Icons.phone_outlined,
      Color(0xFF34A853),
    ),
    'com.samsung.android.calendar': AppIconStyle(
      Icons.calendar_today_outlined,
      Color(0xFF1428A0),
    ),
    'com.sec.android.app.sbrowser': AppIconStyle(
      Icons.language,
      Color(0xFF1428A0),
    ),
  };

  static const _keywordRules = <(List<String>, AppIconStyle)>[
    (
      ['tiktok', 'musically', 'douyin'],
      AppIconStyle(Icons.music_note_outlined, Color(0xFF010101)),
    ),
    (
      ['instagram', 'threads'],
      AppIconStyle(Icons.camera_alt_outlined, Color(0xFFE1306C)),
    ),
    (
      ['youtube'],
      AppIconStyle(Icons.play_circle_outline, Color(0xFFFF0000)),
    ),
    (
      ['whatsapp'],
      AppIconStyle(Icons.chat_outlined, Color(0xFF25D366)),
    ),
    (
      ['snapchat'],
      AppIconStyle(Icons.photo_camera_outlined, Color(0xFFC7B800)),
    ),
    (
      ['facebook'],
      AppIconStyle(Icons.facebook_outlined, Color(0xFF1877F2)),
    ),
    (
      ['messenger'],
      AppIconStyle(Icons.chat_bubble_outline, Color(0xFF0084FF)),
    ),
    (['twitter', 'tweet'], AppIconStyle(Icons.tag, Color(0xFF000000))),
    (['reddit'], AppIconStyle(Icons.forum_outlined, Color(0xFFFF4500))),
    (['discord'], AppIconStyle(Icons.headphones_outlined, Color(0xFF5865F2))),
    (['telegram'], AppIconStyle(Icons.send_outlined, Color(0xFF229ED9))),
    (['netflix'], AppIconStyle(Icons.movie_outlined, Color(0xFFE50914))),
    (['spotify'], AppIconStyle(Icons.library_music_outlined, Color(0xFF1DB954))),
    (
      ['gmail', 'outlook', 'mail', 'email'],
      AppIconStyle(Icons.mail_outline, Color(0xFFEA4335)),
    ),
    (
      ['chrome', 'firefox', 'browser', 'opera', 'brave', 'edge'],
      AppIconStyle(Icons.language, Color(0xFF4285F4)),
    ),
    (
      ['maps', 'waze', 'map'],
      AppIconStyle(Icons.map_outlined, Color(0xFF34A853)),
    ),
    (['camera'], AppIconStyle(Icons.photo_camera_outlined, Color(0xFF4E3B31))),
    (['gallery', 'photos', 'photo'], AppIconStyle(Icons.photo_library_outlined, Color(0xFFFABC05))),
    (['message', 'sms', 'messaging'], AppIconStyle(Icons.sms_outlined, Color(0xFF1A73E8))),
    (['dialer', 'phone', 'call'], AppIconStyle(Icons.phone_outlined, Color(0xFF34A853))),
    (['calendar'], AppIconStyle(Icons.calendar_today_outlined, Color(0xFF4285F4))),
    (['clock', 'alarm'], AppIconStyle(Icons.access_time_outlined, Color(0xFF4E3B31))),
    (['calculator', 'calc'], AppIconStyle(Icons.calculate_outlined, Color(0xFF4E3B31))),
    (['settings'], AppIconStyle(Icons.settings_outlined, Color(0xFF4E3B31))),
    (['contact'], AppIconStyle(Icons.contacts_outlined, Color(0xFF4285F4))),
    (['music', 'podcast', 'audio'], AppIconStyle(Icons.library_music_outlined, Color(0xFF1DB954))),
    (
      ['video', 'movie', 'tv', 'stream', 'player'],
      AppIconStyle(Icons.movie_outlined, Color(0xFFFF0000)),
    ),
    (
      ['game', 'esport'],
      AppIconStyle(Icons.sports_esports_outlined, Color(0xFF5865F2)),
    ),
    (
      ['shop', 'store', 'amazon', 'ebay', 'temu', 'shein', 'wish'],
      AppIconStyle(Icons.shopping_bag_outlined, Color(0xFFFF9900)),
    ),
    (
      ['bank', 'pay', 'wallet', 'finance', 'revolut'],
      AppIconStyle(Icons.payments_outlined, Color(0xFF003087)),
    ),
    (['news'], AppIconStyle(Icons.newspaper_outlined, Color(0xFF4E3B31))),
    (['note', 'keep'], AppIconStyle(Icons.sticky_note_2_outlined, Color(0xFFFBBC04))),
    (['drive', 'files', 'folder', 'document'], AppIconStyle(Icons.folder_outlined, Color(0xFF4285F4))),
    (['weather'], AppIconStyle(Icons.wb_cloudy_outlined, Color(0xFF1A73E8))),
    (['fitness', 'health', 'workout'], AppIconStyle(Icons.fitness_center_outlined, Color(0xFFE1306C))),
    (['food', 'eat', 'restaurant', 'uber.eats'], AppIconStyle(Icons.restaurant_outlined, Color(0xFF06C167))),
    (['taxi', 'uber', 'bolt', 'ride'], AppIconStyle(Icons.local_taxi_outlined, Color(0xFF000000))),
    (
      ['tinder', 'bumble', 'dating'],
      AppIconStyle(Icons.favorite_border, Color(0xFFFE3C72)),
    ),
    (['chat'], AppIconStyle(Icons.chat_outlined, Color(0xFF25D366))),
  ];

  static AppIconStyle forApp({
    required String packageName,
    required String name,
  }) {
    final known = _packages[packageName];
    if (known != null) {
      return known;
    }
    final haystack = '${packageName.toLowerCase()} ${name.toLowerCase()}';
    for (final rule in _keywordRules) {
      for (final keyword in rule.$1) {
        if (haystack.contains(keyword)) {
          return rule.$2;
        }
      }
    }
    return AppIconStyle(Icons.apps_outlined, _colorFor(packageName));
  }

  static Color _colorFor(String value) {
    return _palette[value.hashCode.abs() % _palette.length];
  }
}
