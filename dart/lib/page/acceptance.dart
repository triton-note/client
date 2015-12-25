library triton_note.page.acceptance;

import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/util/cordova.dart';

final Logger _logger = new Logger('AcceptancePage');

const gistId = '23ac8b82bab0b512f8a4';

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

@Component(
    selector: 'acceptance',
    templateUrl: 'packages/triton_note/page/acceptance.html',
    cssUrl: 'packages/triton_note/page/acceptance.css',
    useShadowDom: true)
class AcceptancePage implements ShadowRootAware {
  final Router _router;

  AcceptancePage(this._router);

  void onShadowRoot(ShadowRoot root) {
    _showGist(DivElement div, String styleHref) async {
      final base = root.querySelector('div.gist');

      if (styleHref != null) {
        final css = (await HttpRequest.request(styleHref)).responseText;
        base.append(new StyleElement()..text = css);
      }

      div.querySelector('.gist-meta')?.remove();
      base.append(div);

      hideSplashScreen();
    }

    final callbackName = 'gistCallback';
    context[callbackName] = (res) {
      _logger.finest(() => "Callback response: ${_stringify(res)}");
      final divString = res['div'];
      if (divString != null) {
        String toHref(String styleString) {
          if (styleString == null) return null;

          if (styleString.startsWith('<link')) {
            final plain = styleString.replaceAll(r"\\", '');
            final regex = new RegExp(r'href=\"([^\s]*)\"');
            return regex.firstMatch(plain).group(1);
          }

          if (!styleString.startsWith('http')) {
            final sep = styleString.startsWith('/') ? '' : '/';
            return "https://gist.github.com${sep}${styleString}";
          }

          return styleString;
        }
        _showGist(new Element.html(divString), toHref(res['stylesheet']));
      }
    };
    document.body.append(new ScriptElement()..src = "https://gist.github.com/${gistId}.json?callback=${callbackName}");
  }

  accept() {
    _logger.warning(() => "User accepted privacy policy");
    window.localStorage['acceptance'] = 'true';
    _router.go('home', {});
  }
}
