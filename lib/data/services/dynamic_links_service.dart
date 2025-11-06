import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:logger/logger.dart';
import '../../core/env.dart';

/// Dynamic Links service for referrals
class DynamicLinksService {
  final _logger = Logger();

  /// Create referral link
  Future<String?> createReferralLink(String inviterUid) async {
    try {
      final dynamicLinkParams = DynamicLinkParameters(
        link: Uri.parse('${Env.dynamicLinksPrefix}/?inviter=$inviterUid'),
        uriPrefix: Env.dynamicLinksPrefix,
        androidParameters: const AndroidParameters(
          packageName: Env.androidAppId,
          minimumVersion: 0,
        ),
        iosParameters: const IOSParameters(
          bundleId: Env.iosBundleId,
          minimumVersion: '0',
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: 'Join me on I AM!',
          description: 'Can you solve these riddles?',
        ),
      );

      final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
      _logger.i('Created referral link: ${shortLink.shortUrl}');
      return shortLink.shortUrl.toString();
    } catch (e, stack) {
      _logger.e('Failed to create referral link', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Handle incoming dynamic link
  Future<String?> handleDynamicLink(PendingDynamicLinkData? linkData) async {
    if (linkData == null) return null;

    try {
      final deepLink = linkData.link;
      final inviterUid = deepLink.queryParameters['inviter'];
      _logger.i('Received referral from: $inviterUid');
      return inviterUid;
    } catch (e, stack) {
      _logger.e('Failed to handle dynamic link', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Initialize dynamic links listener
  Future<void> initDynamicLinks(Function(String inviterUid) onReferral) async {
    try {
      // Handle link when app is in background/terminated
      final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
      if (initialLink != null) {
        final inviterUid = await handleDynamicLink(initialLink);
        if (inviterUid != null) {
          onReferral(inviterUid);
        }
      }

      // Handle links when app is active
      FirebaseDynamicLinks.instance.onLink.listen((linkData) async {
        final inviterUid = await handleDynamicLink(linkData);
        if (inviterUid != null) {
          onReferral(inviterUid);
        }
      });

      _logger.i('Dynamic Links listener initialized');
    } catch (e, stack) {
      _logger.e('Failed to init dynamic links', error: e, stackTrace: stack);
    }
  }
}
