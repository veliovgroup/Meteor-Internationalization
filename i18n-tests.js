if(Meteor.isClient){

  Tinytest.add('setLocale()', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.currentLocale, 'en');

    i18n.setLocale('de');
    test.equal(i18n.currentLocale, 'de');
    test.notEqual(i18n.currentLocale, 'asdf');
  });

  // Tinytest.add('setLocale() exeption', function (test) {
  //   test.exception(i18n.setLocale('enen'));
  //   test.expect_fail();
  // });

  Tinytest.add('get() non-existent key', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.get('de', 'samle.hell', ['o', 'b']), 'samle.hell');

    i18n.setLocale('de');
    test.equal(i18n.get('samle.hell'), 'samle.hell');
  });

  Tinytest.add('get()', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.get('sample.hello'), 'Hello');

    i18n.setLocale('de');
    test.equal(i18n.get('sample.hello'), 'Hallo');
  });

  Tinytest.add('get(locale, param) [different lang than current locale]', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.get('de', 'sample.hello'), 'Hallo');

    i18n.setLocale('de');
    test.equal(i18n.get('en', 'sample.hello'), 'Hello');
  });

  Tinytest.add('get() from nested folder', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.get('nested.folder.is.support.nested.objects'), 'too');

    i18n.setLocale('de');
    test.equal(i18n.get('nested.folder.is.support.nested.objects'), 'zu');
  });

  Tinytest.add('get() with placeholder', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.get('sample.userHello', 'ostrio'), 'Hi ostrio!');

    i18n.setLocale('de');
    test.equal(i18n.get('sample.userHello', 'ostrio'), 'Hallo ostrio!');
  });

  Tinytest.add('get() with placeholders', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.get('sample.fullName', ['Michael', 'A.', 'Macht']), 'User\'s full name is: Michael A. Macht');

    i18n.setLocale('de');
    test.equal(i18n.get('sample.fullName', {first: 'Michael', middle: 'A.', last: 'Macht'}), 'Vollständige Name des Benutzers ist: Michael A. Macht');
  });

  Tinytest.add('get() with wrong placeholders', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.get('sample.fullName', {first: 'Michael', middle: 'A.', third: 'Macht'}), 'User\'s full name is: Michael A. ');

    i18n.setLocale('de');
    test.equal(i18n.get('sample.fullName', {first: 'Michael', middle: 'A.', third: 'Macht'}), 'Vollständige Name des Benutzers ist: Michael A. ');
  });

  Tinytest.add('get() with placeholders as parameters', function (test) {
    i18n.setLocale('en');
    test.equal(i18n.get('sample.fullName', 'Michael', 'A.', 'Macht'), 'User\'s full name is: Michael A. Macht');

    i18n.setLocale('de');
    test.equal(i18n.get('sample.fullName', 'Michael', 'A.', 'Macht'), 'Vollständige Name des Benutzers ist: Michael A. Macht');
  });
}

if(Meteor.isServer){
  Tinytest.add('get() without locale', function (test) {
    test.equal(i18n.get('sample.hell'), 'sample.hell');
    test.equal(i18n.get('sample.hello'), 'Hello');
    test.equal(i18n.get('sample.userHello', 'ostrio'), 'Hi ostrio!');
    test.equal(i18n.get('sample.fullName', ['Michael', 'A.', 'Macht']), 'User\'s full name is: Michael A. Macht');
    test.equal(i18n.get('sample.fullName', {first: 'Michael', middle: 'A.', third: 'Macht'}), 'User\'s full name is: Michael A. ');
  });

  Tinytest.add('get() with placeholder', function (test) {
    test.equal(i18n.get('en', 'sample.userHello', 'ostrio'), 'Hi ostrio!');
    test.equal(i18n.get('de', 'sample.userHello', 'ostrio'), 'Hallo ostrio!');
  });

  Tinytest.add('get() with placeholders', function (test) {
    test.equal(i18n.get('en', 'sample.fullName', ['Michael', 'A.', 'Macht']), 'User\'s full name is: Michael A. Macht');
    test.equal(i18n.get('de', 'sample.fullName', {first: 'Michael', middle: 'A.', last: 'Macht'}), 'Vollständige Name des Benutzers ist: Michael A. Macht');
  });

  Tinytest.add('get() from nested folder', function (test) {
    test.equal(i18n.get('en', 'nested.folder.is.support.nested.objects'), 'too');
    test.equal(i18n.get('de', 'nested.folder.is.support.nested.objects'), 'zu');
  });

  Tinytest.add('get() with wrong placeholders', function (test) {
    test.equal(i18n.get('en', 'sample.fullName', {first: 'Michael', middle: 'A.', third: 'Macht'}), 'User\'s full name is: Michael A. ');

    test.equal(i18n.get('de', 'sample.fullName', {first: 'Michael', middle: 'A.', third: 'Macht'}), 'Vollständige Name des Benutzers ist: Michael A. ');
  });

  Tinytest.add('get() non-existent key', function (test) {
    test.equal(i18n.get('en', 'samle.hell'), 'samle.hell');
    test.equal(i18n.get('de', 'samle.hell'), 'samle.hell');
  });

  Tinytest.add('get() with placeholders as parameters', function (test) {
    test.equal(i18n.get('en', 'sample.fullName', 'Michael', 'A.', 'Macht'), 'User\'s full name is: Michael A. Macht');
    test.equal(i18n.get('de', 'sample.fullName', 'Michael', 'A.', 'Macht'), 'Vollständige Name des Benutzers ist: Michael A. Macht');
  });

  Tinytest.add('get() with placeholders as parameters with callback', function (test) {
    test.equal(i18n.get('en', 'sample.fullName', 'Michael', 'A.', 'Macht', function(){ console.log("i18n on Server after render callback", arguments) }), 'User\'s full name is: Michael A. Macht');
    test.equal(i18n.get('de', 'sample.fullName', 'Michael', 'A.', 'Macht', function(){ console.log("i18n on Server after render callback", arguments) }), 'Vollständige Name des Benutzers ist: Michael A. Macht');
  });
}