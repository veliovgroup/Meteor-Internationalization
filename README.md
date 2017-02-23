Reactive i18n and l10n isomorphic driver
========
Object based, fast, lightweight (*312 lines with comments*) and reactive internationalization isomorphic driver for Meteor with support of placeholders.

Install:
========
```shell
meteor add ostrio:i18n
```

Import:
========
```jsx
import I18N from 'meteor/ostrio:i18n';
```

### Object-based structure
```jsx
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
      return '<a href="/' + this.currentLocale.get() + '/info">info</a>';
    }
  },
  en:{ //--> Localization with key of country two-letter code
    property: "value",
    property2: {
      nestedProp: "value"
    },
    dynamicProperty(){
      return '<a href="/' + this.currentLocale.get() + '/info">info</a>';
    }
  }
  ...
};

import I18N from 'meteor/ostrio:i18n';
const i18n = new I18N({i18n: i18nConfig});
```

Initialization
========
```jsx
import I18N from 'meteor/ostrio:i18n';
const i18n = new I18N(config);
```

 - `config.i18n`               {*Object*}  - [Internalization object](https://github.com/VeliovGroup/Meteor-Internationalization#object-based-structure)
 - `config.returnKey`          {*Boolean*} - Return key if l10n value not found, default: `true`
 - `config.helperName`         {*String*}  - Template helper name, default: `i18n`
 - `config.helperSettingsName` {*String*}  - Settings helper name, default: `i18nSettings`

API
========
##### `get([locale,] key, [replacements...])`
 - `locale` {*String*} - [Optional] Two-letter locale string, used to force locale, if not set __current locale__ is used
 - `key`    {*String*} - l10n key like: `folder.file.object.key`
 - `replacements..` {*String*|[*String*]|*Object*} - [Optional] Replacements for placeholders in l10n string
```jsx
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

```jsx
i18n.has('file.obj.key'); // Current locale
i18n.has(locale, param); // Force locale
i18n.has('ca', 'file.obj.key'); //false
i18n.has('en', 'file.obj.key'); //true
```

##### `setLocale(locale)`
 - `locale` {*String*} - Two-letter locale code
```jsx
i18n.setLocale(locale);
```

##### Get current localization at any environment
```jsx
i18n.currentLocale.get(); // Reactive on Client
```

##### Get current default locale
```jsx
i18n.defaultLocale;
```

##### Get configuration object
```jsx
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
```jsx
i18n.getSetting('current'); // en
```

Client specific usage
================
##### Client's browser locale
```jsx
i18n.userLocale; // en-US
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
```jsx
Template.langSwitch.helpers({
  currentLocale(){
    return i18n.currentLocale.get()
  }
});

Template.langSwitch.events({
  'click .switch-language'(e, template) {
    e.preventDefault();
    i18n.setLocale(e.currentTarget.dataset.code);
    return false;
  }
});
```

Template helpers `compare`, `==`, `Session` and many more comes from: [ostrio:templatehelpers](https://atmospherejs.com/ostrio/templatehelpers) package