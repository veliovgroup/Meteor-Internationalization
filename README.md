Reactive i18n and l10n isomorphic service for Meteor
========
File based, fast, lightweight (*325 lines with comments*) and reactive internationalization isomorphic driver for Meteor with support of placeholders.

Demo
========
 - Please see [Mongo-based live demo](http://internalization.meteor.com)
 - Please see [Object-based live demo](http://internalization-object.meteor.com)
 - Demo [source code](https://github.com/VeliovGroup/Meteor-Internationalization/tree/master/demo)

Install:
========
```shell
meteor add ostrio:i18n
```

### Object-based structure
```javascript
/* Isomorphic (Both server and client) */
i18nConfig = {
  settings: { //--> Config object
    defaultLocale: "en",
    ru: {
      code: "ru",
      isoCode: "ru-RU",
      name: "Русский"
    },
    en: {
      code: "en",
      isoCode: "en-US",
      name: "English"
    }
  },
  ru:{ //--> Localization with key of country two-letter code
    property: "value",
    property2: {
      nestedProp: "value"
    },
    dynamicProperty: function(){
      return '<a href="/' + this.currentLocale.get() + '/info">info</a>';
    }
  },
  en:{ //--> Localization with key of country two-letter code
    property: "value",
    property2: {
      nestedProp: "value"
    },
    dynamicProperty: function(){
      return '<a href="/' + this.currentLocale.get() + '/info">info</a>';
    }
  }
  ...
};

this.i18n = new I18N({driver: 'Object', i18n: i18nConfig});
```

### Mongo-based Files and Folders structure
```schema
 private/
 └─ i18n/ //--> Driver's dir
    |
    ├── en/ //--> Localization folder with name of country two-letter code
    |   ├── file.json
    |   └── subFolder/ 
    |       └── anotherFile.json
    |
    ├── de/ //--> Localization folder with name of country two-letter code
    |   ├── file.json
    |   └── subFolder/ 
    |       └── anotherFile.json
    |
    └── i18n.json //--> Config file
```

Initialization
========
```javascript
this.i18n = new I18N(config);
// `this` is used to create application wide variable
```

__Configuration object__:
 - `config.driver` {String: *Mongo*|*Object*} - Driver type. Use `Mongo` for file-based and `Object` object-based
 - `config.i18n`               {*Object*}  - [Internalization object](https://github.com/VeliovGroup/Meteor-Internationalization#object-based-structure)
 - `config.path`               {*String*}  - Path to `i18n` folder, default: `/assets/app/i18n` (*which points to:* `private/i18n` *in dev environment*)
 - `config.returnKey`          {*Boolean*} - Return key if l10n value not found, default: `true`
 - `config.collectionName`     {*String*}  - i18n Collection name, default: `internalization`
 - `config.helperName`         {*String*}  - Template helper name, default: `i18n`
 - `config.helperSettingsName` {*String*}  - Settings helper name, default: `i18nSettings`
 - `config.allowPublishAll`    {*Boolean*} - Allow publish full i18n set to client, default: `true`


Isomorphic usage
========
##### `get([locale,] key, [replacements...])`
 - `locale` {*String*} - [Optional] Two-letter locale string, used to force locale, if not set __current locale__ is used
 - `key`    {*String*} - l10n key like: `folder.file.object.key`
 - `replacements..` {*String*|[*String*]|*Object*} - [Optional] Replacements for placeholders in l10n string
```javascript
i18n.get('file.obj.key'); // Current locale, no replacements

i18n.get(locale, param); // Force locale, no replacements
i18n.get('en', 'file.obj.key');

i18n.get(param, replacements); // Current locale, with replacements
i18n.get('file.obj.key', 'User Name'); // Hello {{username}} -> Hello User Name

i18n.get(locale, param, replacements); // Force locale, with replacements
i18n.get('en', 'file.obj.key', 'User Name'); // Hello {{username}} -> Hello User Name
```

##### `has([locale,] key)`
*Determine whenever key is exists in configuration file(s).*

 - `locale` {*String*} - [Optional] Two-letter locale string, used to force locale, if not set __current locale__ is used
 - `key`    {*String*} - l10n key like: `folder.file.object.key`

```javascript
i18n.has('file.obj.key'); // Current locale
i18n.has(locale, param); // Force locale
i18n.has('ca', 'file.obj.key'); //false
i18n.has('en', 'file.obj.key'); //true
```

##### `setLocale(locale)`
 - `locale` {*String*} - Two-letter locale code
```javascript
i18n.setLocale(locale);
```

##### Get current localization at any environment
```javascript
i18n.currentLocale.get(); // Reactive on Client
```

##### Get current default locale
```javascript
i18n.defaultLocale;
```

##### Get configuration object
```javascript
i18n.langugeSet();
/* Returns:
{
  current: 'en', // Current locale
  locales: ['ru', en], // List of locales
  // All locales
  all: [{
    code: "ru",
    isoCode: "ru-RU",
    name: "Русский",
    path: "i18n/ru/"
  },{
    code: "en",
    isoCode: "en-US",
    name: "English",
    path: "i18n/en/"
  }],
  // All locales except current
  other: [{
    code: "ru",
    isoCode: "ru-RU",
    name: "Русский",
    path: "i18n/ru/"
  }],
}
*/
```

##### Get specific key from configuration object
 - `key` {*String*} - One of the keys: `current`, `all`, `other`, `locales`, `currentISO`, `currentName`, `currentPath`
```javascript
i18n.getSetting('current'); // en
```

Client specific usage
================
##### Client's browser locale
```javascript
i18n.userLocale; // en-US
```

##### `subscribeToAll(callback)`
 - `callback` {*Function*} - Callback function triggered right after subscription is ready
Send full i18n and l10n set to client, might be used within `iron-router` and `fastrender` packages, example:
```javascript
i18n = new I18N();
Router.route('index', {
  path: '/',
  fastRender: true,
  waitOn: function() {
    return i18n.subscribeToAll();
  }
});
```

Template helpers
================
`i18n` - accepts `locale`, `key` and `replacements`:
*You may change name of the helper via config object: `config.helperName`*
```html
<p>{{i18n 'sample.hello'}}</p>
<p>{{{i18n 'sample.html'}}}</p>
<p>{{i18n 'sample.fullName'}}</p>
<p>{{i18n 'sample.fullName' 'Michael' 'A.' 'Macht'}}</p>
<p>{{i18n 'en' 'sample.fullName' 'Michael' 'A.' 'Macht'}}</p>
<p>{{i18n 'de' 'sample.fullName' first='Michael' middle='A.' last='Macht'}}</p>
<p>{{i18n 'sample.fullName' first='Michael' middle='A.' last='Macht'}}</p>
<p>{{i18n 'sample.fullName' first='Michael' middle='A.' third='Macht'}}</p>
```

`i18nSettings` - accepts configuration object key, one of `current`, `all`, `other`, `locales`
*You may change name of the helper via config object: `config.helperSettingsName`*
```html
{{#each i18nSettings 'all'}}
  ...
{{/each}}
```

##### Template language switcher example
```html
<template name="langSwitch">
  {{#each i18nSettings 'all'}}
    {{#if compare code '==' currentLocale}}
      <span title="Current language">{{name}}</span>&nbsp;
    {{else}}
      <a href="#" data-code="{{code}}" class="switch-language">{{name}}</a>&nbsp;
    {{/if}}
  {{/each}}
</template>
```
```javascript
Template.langSwitch.helpers({
  currentLocale: function(){
    return i18n.currentLocale.get()
  }
});

Template.langSwitch.events({
  'click .switch-language': function(e, template) {
    e.preventDefault();
    i18n.setLocale(e.currentTarget.dataset.code);
    return false;
  }
});
```

Template helpers `compare`, `==`, `Session` and many more comes from: [ostrio:templatehelpers](https://atmospherejs.com/ostrio/templatehelpers) package