Package.describe({
  name: 'ostrio:i18n',
  summary: 'Super-Lightweight and fast i18n isomorphic driver for Meteor with support of placeholders.',
  version: '3.2.0',
  git: 'https://github.com/VeliovGroup/Meteor-Internationalization',
  documentation: 'README.md'
});

Package.onUse(function (api) {
  api.versionsFrom('1.6.1');
  api.use(['check', 'reactive-var', 'ecmascript', 'ostrio:cstorage@4.0.1'], ['client', 'server']);
  api.mainModule('i18n.js', ['client', 'server']);
});
