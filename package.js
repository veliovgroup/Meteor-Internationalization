Package.describe({
  name: 'ostrio:i18n',
  summary: 'Super-Lightweight and fast i18n isomorphic driver for Meteor with support of placeholders.',
  version: '3.0.3',
  git: 'https://github.com/VeliovGroup/Meteor-Internationalization',
  documentation: 'README.md'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4');
  api.use(['underscore', 'check', 'reactive-var', 'ecmascript', 'ostrio:cstorage@2.2.1'], ['client', 'server']);
  api.use(['templating', 'tracker'], 'client');
  api.mainModule('i18n.js', ['client', 'server']);
});
