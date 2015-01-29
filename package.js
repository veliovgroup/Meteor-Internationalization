Package.describe({
  name: 'ostrio:i18n',
  summary: 'i18n and l10n package built with usage of meteor collections, '+
           'with both server- and client-side support',
  version: '1.0.0',
  git: '',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.3.1');
  api.use('coffeescript', ['client', 'server']);
  api.use('ostrio:cstorage@0.0.1', 'client');
  api.use('ostrio:jsextensions@0.0.1', ['client', 'server']);
  api.use('meteorhacks:npm@1.2.2');
  api.addFiles(['ostrio:i18n.coffee', 'ostrio:collection.coffee'], ['client', 'server']);
  api.use('underscore', ['client', 'server']);
  api.use('session', 'client');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('coffeescript', ['client', 'server']);
  api.use('ostrio:i18n');
  api.addFiles('ostrio:i18n-tests.js');
});

Npm.depends({
  'fs-extra': '0.16.3',
  fibers: '1.0.2'
  // mkdirp: '0.5.0'
});