Package.describe({
  name: 'ostrio:i18n',
  summary: 'Reactive and fast i18n isomorphic driver for Meteor with support of placeholders.',
  version: '1.5.0',
  git: 'https://github.com/VeliovGroup/Meteor-Internationalization',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  api.use(['underscore', 'sha', 'ostrio:jsextensions@0.0.4', 'coffeescript'], ['client', 'server']);
  api.use(['session', 'templating', 'ostrio:cstorage@1.0.0'], 'client');
  api.use('ostrio:meteor-root@1.0.0', 'server')
  api.addFiles(['i18n.coffee', 'collection.coffee'], ['client', 'server']);
});

Package.onTest(function(api) {
  api.use(['coffeescript', 'ostrio:i18n', 'tinytest'], ['client', 'server']);
  api.addFiles('i18n-tests.js');
});

Npm.depends({
  'fs-extra': '0.22.1'
});