[![support](https://img.shields.io/badge/support-GitHub-white)](https://github.com/sponsors/dr-dimitru)
[![support](https://img.shields.io/badge/support-PayPal-white)](https://paypal.me/veliovgroup)
<a href="https://ostr.io/info/built-by-developers-for-developers">
  <img src="https://ostr.io/apple-touch-icon-60x60.png" height="20">
</a>

# Reactive i18n and l10n isomorphic driver

Object based, fast, lightweight (*334 lines with comments*) and reactive internationalization isomorphic driver for Meteor with support of placeholders, and user's locale auto-detection.

Not tied to Blaze, can be used with Vue.js, React.js or any other JS solution.

## Install:

```shell
meteor add ostrio:i18n
```

## Import:

```js
import I18N from 'meteor/ostrio:i18n';
```

### Object-based structure

```js
/* Isomorphic (Both Server and Client) */
const i18nConfig = {
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
    dynamicProperty(){
      return `<a href="/${this.currentLocale.get()}/info">info</a>`;
    }
  },
  en:{ //--> Localization with key of country two-letter code
    property: "value",
    property2: {
      nestedProp: "value"
    },
    dynamicProperty(){
      return `<a href="/${this.currentLocale.get()}/info">info</a>`;
    }
  }
  ...
};

import I18N from 'meteor/ostrio:i18n';
const i18n = new I18N({i18n: i18nConfig});
```

## Initialization

```js
import I18N from 'meteor/ostrio:i18n';
const i18n = new I18N(config);
```

- `config.i18n` {*Object*}  - [Internalization object](https://github.com/VeliovGroup/Meteor-Internationalization#object-based-structure)
- `config.returnKey` {*Boolean*} - Return key if l10n value not found, default: `true`
- `config.helperName` {*String*}  - Template helper name, default: `i18n`
- `config.helperSettingsName` {*String*}  - Settings helper name, default: `i18nSettings`

## API

### `get([locale,] key, [replacements...])`

- `locale` {*String*} - [Optional] Two-letter locale string, used to force locale, if not set __current locale__ is used
- `key` {*String*} - l10n key like: `object.path.to.key`
- `replacements..` {*String*|[*String*]|*Object*} - [Optional] Replacements for placeholders in l10n string

```js
i18n.get('object.path.to.key'); // Current locale, no replacements

i18n.get(locale, param); // Force locale, no replacements
i18n.get('en', 'object.path.to.key');

i18n.get(param, replacements); // Current locale, with replacements
i18n.get('object.path.to.key', 'Michael'); // Hello {{username}} -> Hello Michael

i18n.get(locale, param, replacements); // Force locale, with replacements
i18n.get('en', 'object.path.to.key', 'John Doe'); // Hello {{username}} -> Hello John Doe
```

### `has([locale,] key)`

*Determine whenever key is exists in configuration file(s).*

- `locale` {*String*} - [Optional] Two-letter locale string, used to force locale, if not set __current locale__ is used
- `key` {*String*} - l10n key like: `object.path.to.key`

```js
i18n.has('object.path.to.key'); // Current locale
i18n.has(locale, param); // Force locale
i18n.has('ca', 'object.path.to.key'); //false
i18n.has('en', 'object.path.to.key'); //true
```

### `setLocale(locale)`

- `locale` {*String*} - Two-letter locale code

```js
i18n.setLocale(locale);
```

### `addl10n(l10n)`

- `l10n` {*Object*} - Object with language set

```js
i18n.addl10n({
  en: { // <- Object's root is the language two-letter code
    newKey: "New Value"
  }
});
```

### Get current localization at any environment

```js
i18n.currentLocale.get(); // Reactive on Client
```

### Get current default locale

```js
i18n.defaultLocale;
```

### Get configuration object

```js
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

### Get specific key from configuration object

- `key` {*String*} - One of the keys: `current`, `all`, `other`, `locales`, `currentISO`, `currentName`, `currentPath`

```js
i18n.getSetting('current'); // en
```

### Blaze specific usage

Usage in Blaze templating

#### Client's browser locale

```js
i18n.userLocale; // en-US
```

#### Template helpers

__Template helpers requires__ `templating` __package to be installed__. `i18n` helper - accepts `locale`, `key` and `replacements`

```handlebars
<p>{{i18n 'sample.hello'}}</p>
<p>{{{i18n 'sample.html'}}}</p>
<p>{{i18n 'sample.fullName'}}</p>
<p>{{i18n 'sample.fullName' 'Michael' 'A.' 'Macht'}}</p>
<p>{{i18n 'en' 'sample.fullName' 'Michael' 'A.' 'Macht'}}</p>
<p>{{i18n 'de' 'sample.fullName' first='Michael' middle='A.' last='Macht'}}</p>
<p>{{i18n 'sample.fullName' first='Michael' middle='A.' last='Macht'}}</p>
<p>{{i18n 'sample.fullName' first='Michael' middle='A.' third='Macht'}}</p>
```

*Change name of the helper via config object: `config.helperName`*

`i18nSettings` - accepts configuration object key, one of `current`, `all`, `other`, `locales`

```handlebars
{{#each i18nSettings 'all'}}
  ...
{{/each}}
```

*Change name of the helper via config object: `config.helperSettingsName`*

#### Template language switcher example

```handlebars
<template name="langSwitch">
  {{#each i18nSettings 'all'}}
    {{#if compare code '==' currentLocale}}
      <span title="Current language">{{name}}</span>&nbsp;
    {{else}}
      <a href="#" data-switch-language="{{code}}">{{name}}</a>&nbsp;
    {{/if}}
  {{/each}}
</template>
```

```js
Template.langSwitch.helpers({
  currentLocale(){
    return i18n.currentLocale.get()
  }
});

Template.langSwitch.events({
  'click [data-switch-language]'(e) {
    e.preventDefault();
    i18n.setLocale(e.currentTarget.dataset.switchLanguage);
    return false;
  }
});
```

Template helpers `compare`, `==`, `Session` and many more comes from: [`ostrio:templatehelpers`](https://atmospherejs.com/ostrio/templatehelpers) package.

## Support this project:

- [Sponsor via GitHub](https://github.com/sponsors/dr-dimitru)
- [Support via PayPal](https://paypal.me/veliovgroup)
- Use [ostr.io](https://ostr.io) — [Monitoring](https://snmp-monitoring.com), [Analytics](https://ostr.io/info/web-analytics), [WebSec](https://domain-protection.info), [Web-CRON](https://web-cron.info) and [Pre-rendering](https://prerendering.com) for a website
