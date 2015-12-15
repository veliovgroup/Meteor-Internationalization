Package.describe({
  name: 'ostrio:i18n',
  summary: 'Lightweight and fast i18n isomorphic driver for Meteor with support of placeholders.',
  version: '2.1.1',
  git: 'https://github.com/VeliovGroup/Meteor-Internationalization',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2');
  api.use(['underscore', 'coffeescript', 'check', 'reactive-var', 'meteorhacks:subs-manager@1.6.2'], ['client', 'server']);
  api.use(['templating', 'ostrio:cstorage@2.0.1', 'tracker'], 'client');
  api.use('ostrio:meteor-root@1.0.2', 'server')
  api.addFiles('i18n.coffee', ['client', 'server']);
  api.export('I18N', ['server', 'client']);
});

Npm.depends({
  'fs-extra': '0.26.2'
});