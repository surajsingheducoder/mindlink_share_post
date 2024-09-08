import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class ShareDynamicLink {
  Future<String?> createDynamicLink(String postId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://mindlinkapp.page.link',
      link: Uri.parse('https://mindlinkapp.page.link/post/$postId'),
      navigationInfoParameters: const NavigationInfoParameters(
        forcedRedirectEnabled: true
      ),
      iosParameters: IOSParameters(
        bundleId: 'com.example.mindlinkApp',
        minimumVersion: '1.0.1',
        appStoreId: '123456789',
        fallbackUrl: Uri.parse('https://mindlink.in'),
      ),
      androidParameters: AndroidParameters(
        packageName: 'com.example.mindlink_app',
        minimumVersion: 0,
        fallbackUrl: Uri.parse('https://mindlink.in'),
      ),
      socialMetaTagParameters: const SocialMetaTagParameters(
        title: "Check out this post",
        description: "Click the link to see the post.",
      ),
    );

    try {
      final ShortDynamicLink shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
      return shortLink.shortUrl.toString();
    } catch (e) {
      print("Error creating dynamic link: $e");
      return null;
    }
  }
}