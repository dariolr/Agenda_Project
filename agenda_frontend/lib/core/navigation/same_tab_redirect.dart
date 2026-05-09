import 'same_tab_redirect_stub.dart'
    if (dart.library.html) 'same_tab_redirect_web.dart';

void redirectSameTab(String url) => redirectSameTabImpl(url);
