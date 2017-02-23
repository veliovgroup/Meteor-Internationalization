import { ClientStorage } from 'meteor/ostrio:cstorage';

/*
@private
@locus Anywhere
@name toDottedString
@summary Convert object nested keys into dotted string
*/
const toDottedString = function(obj, prepend = 'i18n') {
  let final = {};
  for (let key in obj) {
    if (_.isFunction(obj[key]) || _.isString(obj[key])) {
      final[prepend + '.' + key] = obj[key];
    } else {
      final = _.extend(final, toDottedString.call(this, obj[key], prepend + '.' + key));
    }
  }
  return final;
};

/*
@private
@locus Anywhere
@name proceedPlaceholders
@summary Replace placeholders with replacements in l10n strings
*/
const proceedPlaceholders = function(string, replacements) {
  if (string) {
    for (let replacement of replacements) {
      let key;
      if (replacement && replacement.hash && _.isObject(replacement.hash)) {
        for (key in replacement.hash) {
          string = string.replace(new RegExp(`\{\{(\s)*(${key})+(\s)*\}\}`, 'ig'), replacement.hash[key]);
        }
      } else if (_.isObject(replacement)) {
        for (key in replacement) {
          string = string.replace(new RegExp(`\{\{(\s)*(${key})+(\s)*\}\}`, 'ig'), replacement[key]);
        }
      } else {
        string = string.replace(/\{\{(\s)*([A-z])+(\s)*\}\}/i, replacement);
      }
    }
  }

  return string;
};

export default class I18N {
  /*
  @locus Anywhere
  @name I18N
  @constructor
  @summary Initialize I18N object with `config`
  @param config                    {Object}
  @param config.i18n               {Object}  - Internalization object
  @param config.returnKey          {Boolean} - Return key if l10n value not found
  @param config.helperName        {String}  - Template main i18n helper name
  @param config.helperSettingsName {String}  - Template i18nSettings helper name
  */
  constructor(config = {}) {
    check(config, Object);

    let object;
    const self              = this;
    this.returnKey          = config.returnKey || true;
    this.helperName        = config.helperName || 'i18n';
    this.helperSettingsName = config.helperSettingsName || 'i18nSettings';
    this.currentLocale      = new ReactiveVar(undefined);

    check(this.returnKey, Boolean);
    check(this.helperName, String);
    check(this.helperSettingsName, String);
    check(config.i18n, Object);

    this.strings = {};
    for (let key in config.i18n) {
      if (key !== 'settings') {
        object = toDottedString.call(this, config.i18n[key], key);
        for (let k in object) {
          this.strings[k] = object[k];
        }
      }
    }

    if (_.isObject(config.i18n)) {
      check(config.i18n.settings, Object);
      this.settings = config.i18n.settings;
      this.defaultLocale = this.settings.defaultLocale;
      this.strings['__settings.__langSet__'] = [];
      this.strings['__settings.__langConfig__'] = [];
      let object1 = toDottedString.call(this, this.settings, '__settings');
      for (let key in object1) {
        this.strings[key] = object1[key];
      }

      for (let key in this.settings) {
        if (this.settings[key] && this.settings[key].code) {
          this.strings['__settings.__langSet__'].push(this.settings[key].code);
          this.strings['__settings.__langConfig__'].push(this.settings[key]);
        }
      }
    }

    this.userLocale = ((Meteor.isClient) ? window.navigator.userLanguage || window.navigator.language || navigator.userLanguage : this.settings.defaultLocale);

    if (Meteor.isClient) {
      /*
      @summary Main `i18n` template helper
      */
      Template.registerHelper(this.helperName, function () {
        return self.get.apply(self, arguments);
      });

      /*
      @summary Settings `i18n` template helper, might be used to build language switcher (see demo folder).
      */
      Template.registerHelper(this.helperSettingsName, function () {
        return self.getSetting.apply(self, arguments);
      });

      if (!this.currentLocale.get()) {
        if (!ClientStorage.get('___i18n.locale___')) {
          for (let lang in this.strings['__settings.__langConfig__']) {
            if (lang.code === this.userLocale) {
              this.currentLocale.set(lang.code);
              ClientStorage.set('___i18n.locale___', lang.code);
            }
            if (lang.isoCode === this.userLocale) {
              this.currentLocale.set(lang.isoCode.substring(0, 2));
              ClientStorage.set('___i18n.locale___', lang.isoCode.substring(0, 2));
            }
          }

          this.currentLocale.set(this.defaultLocale);
          ClientStorage.set('___i18n.locale___', this.defaultLocale);
        } else {
          if (!!~this.strings['__settings.__langSet__'].indexOf(ClientStorage.get('___i18n.locale___'))) {
            this.currentLocale.set(ClientStorage.get('___i18n.locale___'));
          } else {
            this.currentLocale.set(this.defaultLocale);
            ClientStorage.set('___i18n.locale___', this.defaultLocale);
          }
        }
      }
    } else {
      this.defaultLocale = this.settings.defaultLocale;
      this.currentLocale.set(this.defaultLocale);
    }
    if (!this.currentLocale.get()) { this.currentLocale.set(this.defaultLocale); }
  }

  /*
  @locus Anywhere
  @memberOf I18N
  @name get
  @summary Get l10n value by key
  @param locale       {String} - [Optional] Two-letter locale string
  @param key          {String} - l10n key like: `folder.file.object.key`
  @param replacements... {String|[String]|Object} - [Optional] Replacements for placeholders in l10n string
  */
  get() {
    let key, lang, replacements;
    let args = Array.prototype.slice.call(arguments);

    if (!args.length || !args[0] || !_.isString(args[0])) {
      return '';
    }

    if (!~args[0].indexOf('.') && _.isString(args[1])) {
      lang         = args[0];
      key          = args[1];
      replacements = args.slice(2);
    } else {
      lang         = this.currentLocale.get() || this.defaultLocale || 'en';
      key          = args[0];
      replacements = args.slice(1);
    }

    if (lang) {
      const _key = lang + '.' + key;
      let result = (this.strings && this.strings[_key] ? this.strings[_key] : undefined) || (this.returnKey ? _key : '');

      if (_.isFunction(result)) {
        result = result.call(this);
      }

      if ((result !== _key) && result && result.length && Object.keys((replacements[0] && replacements[0].hash ? replacements[0].hash : undefined) || replacements).length) {
        result = proceedPlaceholders(result, replacements);
      }

      return result;
    }

    return (this.returnKey) ? key : '';
  }

  /*
  @locus Anywhere
  @memberOf I18N
  @name has
  @summary Check if key exists in current locale
  @param locale       {String} - [Optional] Two-letter locale string
  @param key          {String} - l10n key like: `folder.file.object.key`
  */
  has() {
    let key, lang;
    let args = Array.prototype.slice.call(arguments);

    if (!args.length || !args[0]) {
      return '';
    }

    if (!~args[0].indexOf('.') && _.isString(args[1])) {
      lang = args[0];
      key  = args[1];
    } else {
      lang = this.currentLocale.get() || this.defaultLocale || 'en';
      key  = args[0];
    }

    if (lang) {
      key = lang + '.' + key;
      return !!(this.strings && this.strings[key] ? this.strings[key] : undefined);
    }

    return false;
  }

  /*
  @locus Anywhere
  @memberOf I18N
  @name setLocale
  @summary Set another locale
  @param locale {String} - Two-letter locale string
  */
  setLocale(locale) {
    check(locale, String);

    if (this.settings && this.settings[locale]) {
      this.currentLocale.set(locale);
      if (Meteor.isClient) {
        ClientStorage.set('___i18n.locale___', locale);
      }
    } else {
      throw new Meteor.Error(404, `No such locale: \"${locale}\"`);
    }
    return this;
  }

  /*
  @locus Anywhere
  @memberOf I18N
  @name getSetting
  @summary Get parsed data by key from i18n.json file
  @param key {String} - One of the keys: 'current', 'all', 'other', 'locales'
  */
  getSetting(key) {
    check(key, Match.Optional(Match.OneOf('current', 'all', 'other', 'locales', 'currentISO', 'currentName')));
    if (key) {
      return this.langugeSet()[key] || undefined;
    }
    return this.langugeSet();
  }

  /*
  @locus Anywhere
  @memberOf I18N
  @name langugeSet
  @summary Get data from i18n config
  */
  langugeSet() {
    let key, current = this.settings[this.currentLocale.get()];
    return {
      current: this.currentLocale.get(),
      currentISO: current.isoCode,
      currentName: current.name,
      all: (() => {
        const result = [];
        for (key in this.settings) {
          if (_.isObject(this.settings[key])) {
            result.push(this.settings[key]);
          }
        }
        return result;
      })(),
      other: (() => {
        const result = [];
        for (key in this.settings) {
          if (_.isObject(this.settings[key]) && (key !== this.currentLocale.get())) {
            result.push(this.settings[key]);
          }
        }
        return result;
      })(),
      locales: (() => {
        const result = [];
        for (key in this.settings) {
          if (_.isObject(this.settings[key])) {
            result.push(this.settings[key].code);
          }
        }
        return result;
      })()
    };
  }
}
