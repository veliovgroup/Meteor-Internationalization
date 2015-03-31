Reactive i18n and i10n isomorphic service for Meteor
========
File based and reactive internationalization isomorphic driver for Meteor with support of placeholders.

Install:
========
```shell
meteor add ostrio:i18n
```

### Files and Folders structure
```
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

This structure with sample data will be automatically added if file `private/i18n/i18n.json` is not exists

Settings
========
##### Return key for non-existent key
```javascript
i18n.onWrongKey.returnKey = true;
i18n.get('nonExistentKey'); // returns key: "nonExistentKey"
i18n.onWrongKey.returnKey = false;
i18n.get('nonExistentKey'); // returns empty string: ""
```

Isomorphic usage
========
##### `get()` method
```javascript
/*
 * @function
 * @namespace i18n
 * @property {function} get          - Get values, and do pattern replaces from current localization
 * @param    {string}   locale       - [OPTIONAL] Two-letter localization code
 * @param    {string}   param        - string in form of dot notation, like: folder1.folder2.file.key.key.key... etc.
 * @param    {mix}      replacements - Object, array, or string of replacements
 */
i18n.get(param); // Current locale, no replacements
i18n.get('file.obj.key');

i18n.get(locale, param); // Force locale, no replacements
i18n.get('en', 'file.obj.key');

i18n.get(param, replacements); // Current locale, with replacements
i18n.get('file.obj.key', 'username'); // Hello {{username}} -> Hello username

i18n.get(locale, param, replacements); // Force locale, with replacements
i18n.get('en', 'file.obj.key', 'username'); // Hello {{username}} -> Hello username
```

##### Get current localization at any environment
```javascript
i18n.currentLocale; // Non-reactive
i18n.locale(); // Reactive
```

##### Get localization value
```javascript
i18n.get(i18n.locale(), 'file.obj.key');
```

##### Get current default locale
```javascript
i18n.defaultLocale;
```

Client usage
================
##### `setLocale()` method
```javascript
/*
 * @function
 * @namespace i18n
 * @property {function} setLocale - Set locale (by ISO code)
 * @description Set new locale if it is configured in /private/i18n/i18n.json config file.
 *              Update session's and localStorage or cookie (via Meteor.storage) dependencies
 * @param {string} locale - Two letter locale code
 */
i18n.setLocale(locale)
```

##### Set locale
```javascript
i18n.setLocale('en');
```

##### Get value by key
```javascript
i18n.get('sample.hello');
```

##### Get value by key in different locale than current
```javascript
i18n.get('de', 'sample.hello');
```

##### Get value by key with single placeholder
```javascript
// Hi {{name}}!
i18n.get('sample.userHello', 'Michael');
```

##### Get value by key with multiply placeholders as Object
```javascript
// User's full name is: {{first}} {{middle}} {{last}}
i18n.get('sample.fullName', {first: 'Michael', middle: 'A.', last: 'Macht'});
```

##### Get value by key with multiply placeholders as Object, with wrong key
__Note: wrong key will be omitted__
```javascript
// User's full name is: {{first}} {{middle}} {{last}}
i18n.get('sample.fullName', {first: 'Michael', middle: 'A.', wrong: 'Macht'});
```

##### Get value by key with multiply placeholders with replacements as arguments
__Note: this example relies on arguments order__
```javascript
// User's full name is: {{first}} {{middle}} {{last}}
i18n.get('sample.fullName', 'Michael', 'A.', 'Macht');
```

##### Get value by key with multiply placeholders as Array
__Note: this example relies on array order__
```javascript
// User's full name is: {{first}} {{middle}} {{last}}
i18n.get('sample.fullName', ['Michael', 'A.', 'Macht']);
```

##### Get configuration object
```javascript
i18n.config;
```

##### Get user's browser locale (preferred locale)
```javascript
i18n.userLocale;
```

##### Get current Client's locale
```javascript
i18n.currentLocale;
```

Server usage
================
__Note:__ Server has no `setLocale()` method

##### Get value in default language by key
```javascript
i18n.get('sample.hello');
i18n.get('sample.userHello', 'Michael');
```

##### Get value by key
```javascript
i18n.get('en', 'sample.hello');
```

##### Get value by key with single placeholder
```javascript
// Hi {{name}}!
i18n.get('de', 'sample.userHello', 'Michael');
```

##### Get value by key with multiply placeholders with replacements as arguments
__Note: this example relies on arguments order__
```javascript
// User's full name is: {{first}} {{middle}} {{last}}
i18n.get('ru', 'sample.fullName', 'Michael', 'A.', 'Macht');
```

##### Get value by key with multiply placeholders as Array
__Note: this example relies on array order__
```javascript
// User's full name is: {{first}} {{middle}} {{last}}
i18n.get('ru', 'sample.fullName', ['Michael', 'A.', 'Macht']);
```

##### Get value by key with multiply placeholders as Object
```javascript
// User's full name is: {{first}} {{middle}} {{last}}
i18n.get('ru', 'sample.fullName', {first: 'Michael', middle: 'A.', last: 'Macht'});
```

##### Get value by key with multiply placeholders as Object, with wrong key
__Note: wrong key will be omitted__
```javascript
// User's full name is: {{first}} {{middle}} {{last}}
i18n.get('de', 'sample.fullName', {first: 'Michael', middle: 'A.', wrong: 'Macht'});
```

Session helpers
================
```javascript
Session.get('i18nCurrentLocale'); // Returns current Two-letter localization code
Session.get('i18nConfig'); // Returns array of configuration objects
```

Template helpers
================
`i18n` - accepts param and replacements:
```jade
p {{i18n 'sample.hello'}}
p {{{i18n 'sample.html'}}}
p {{i18n 'sample.fullName'}}
p {{i18n 'sample.fullName', 'Michael' 'A.' 'Macht'}}
p {{i18n 'en' 'sample.fullName', 'Michael' 'A.' 'Macht'}}
p {{i18n 'de' 'sample.fullName', first='Michael' middle='A.' last='Macht'}}
p {{i18n 'sample.fullName' first='Michael' middle='A.' last='Macht'}}
p {{i18n 'sample.fullName' first='Michael' middle='A.' third='Macht'}}
```


##### Template language switcher example
```html
<template name="i18nSwitcher">
  <ul class="">
    {{#each Session 'i18nConfig'}}
      {{> i18nList}}
    {{/each}}
  </ul>
</template>

<template name="i18nList">
{{#if this.value.code}}
  {{#if compare this.value.code '!==' this.currentLocale}}
    <li>
      <a href="#" onclick="i18n.setLocale('{{this.value.code}}'); return false;">{{this.value.name}}</a>
    </li>
  {{/if}}
{{/if}}
</template>
```

Template helpers `compare`, `!==`, `Session` and many more comes from: [ostrio:templatehelpers](https://atmospherejs.com/ostrio/templatehelpers) package