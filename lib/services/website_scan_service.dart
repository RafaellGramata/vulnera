import 'package:http/http.dart' as http;
import '../models/website_finding.dart';

class WebsiteScanService {
  Future<List<WebsiteFinding>> scanUrl(String url) async {
    final findings = <WebsiteFinding>[];

    var targetUrl = url.trim();
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://$targetUrl';
    }

    final uri = Uri.parse(targetUrl);

    if (uri.scheme == 'https') {
      try {
        final httpUri = uri.replace(scheme: 'http');

        // use a raw request with redirects disabled, so we see the actual
        // first response instead of the auto-followed final destination -
        // http.get() follows redirects by default, which was hiding the
        // real answer (a 200 from the https page it redirected to, not
        // from the original http request)
        final client = http.Client();
        final request = http.Request('GET', httpUri)..followRedirects = false;
        final streamedResponse = await client
            .send(request)
            .timeout(const Duration(seconds: 8));
        client.close();

        // status 300-399 means the server redirected us - that's the
        // correct, secure behavior. anything else means it served content
        // over plain http without redirecting to https
        final isRedirect =
            streamedResponse.statusCode >= 300 &&
            streamedResponse.statusCode < 400;

        if (!isRedirect) {
          findings.add(
            WebsiteFinding(
              title: 'HTTPS Not Enforced',
              description:
                  'The site responds over plain HTTP without redirecting to HTTPS, allowing traffic to be intercepted on shared networks.',
              severity: 'High',
              cvssScore: 7.4,
            ),
          );
        }
      } catch (e) {
        // request failing here is fine too - likely means http is refused outright
      }
    }

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw WebsiteScanException(
        'Could not reach the site. Check the URL and try again.',
      );
    }

    final headers = response.headers;

    if (!headers.containsKey('strict-transport-security')) {
      findings.add(
        WebsiteFinding(
          title: 'Missing HSTS Header',
          description:
              'The Strict-Transport-Security header is missing, so browsers will not automatically enforce HTTPS on future visits.',
          severity: 'Medium',
          cvssScore: 5.9,
        ),
      );
    }

    if (!headers.containsKey('content-security-policy')) {
      findings.add(
        WebsiteFinding(
          title: 'Missing Content-Security-Policy Header',
          description:
              'No Content-Security-Policy header was found, leaving the site more exposed to cross-site scripting (XSS) attacks.',
          severity: 'Medium',
          cvssScore: 6.1,
        ),
      );
    }

    if (!headers.containsKey('x-frame-options')) {
      findings.add(
        WebsiteFinding(
          title: 'Missing X-Frame-Options Header',
          description:
              'No X-Frame-Options header was found, making the site potentially vulnerable to clickjacking attacks.',
          severity: 'Low',
          cvssScore: 3.7,
        ),
      );
    }

    if (!headers.containsKey('x-content-type-options')) {
      findings.add(
        WebsiteFinding(
          title: 'Missing X-Content-Type-Options Header',
          description:
              'No X-Content-Type-Options header was found, which can allow browsers to misinterpret file types (MIME sniffing).',
          severity: 'Low',
          cvssScore: 3.1,
        ),
      );
    }

    return findings;
  }
}

class WebsiteScanException implements Exception {
  final String message;
  WebsiteScanException(this.message);
}
