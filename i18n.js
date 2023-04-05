import { Meteor } from 'meteor/meteor';
import { ReactiveVar } from 'meteor/reactive-var';
import { check, Match } from 'meteor/check';
import { ClientStorage } from 'meteor/ostrio:cstorage';

const clientStorage = new ClientStorage();
const isObject = (obj) => {
  if (!obj) {
    return false;
  }

  return Object.prototype.toString.call(obj) === '[object Object]';
};

/**
 * @private
 * @locus Anywhere
 * @name toDottedString
 * @summary Convert object nested keys into dotted string
 */
const toDottedString = function (obj, prepend = false) {
  let final = {};
  let newKey = '';
  for (let key in obj) {
    if (prepend) {
      newKey = `${prepend}.${key}`;
    } else {
      newKey = key;
    }

    if (typeof obj[key] === 'function' || typeof obj[key] === 'string') {
      final[newKey] = obj[key];
    } else {
      final = Object.assign({}, final, toDottedString.call(this, obj[key], newKey));
    }
  }
  return final;
};

const _allowedDataTypes = ['string', 'number'];
/**
 * @private
 * @locus Anywhere
 * @name proceedPlaceholders
 * @summary Replace placeholders with replacements in l10n strings
 */
const proceedPlaceholders = function (_string, replacements) {
  let string = _string;
  if (string) {
    let key;
    for (let replacement of replacements) {
      if (replacement && replacement.hash && isObject(replacement.hash)) {
        for (key in replacement.hash) {
          if (_allowedDataTypes.includes(typeof replacement.hash[key])) {
            string = string.replace(new RegExp(`\{\{(\s)*(${key})+(\s)*\}\}`, 'ig'), replacement.hash[key]);
          }
        }
      } else if (isObject(replacement)) {
        for (key in replacement) {
          if (_allowedDataTypes.includes(typeof replacement[key])) {
            string = string.replace(new RegExp(`\{\{(\s)*(${key})+(\s)*\}\}`, 'ig'), replacement[key]);
          }
        }
      } else if (_allowedDataTypes.includes(typeof replacement)) {
        string = string.replace(/\{\{(\s)*([A-z])+(\s)*\}\}/i, replacement);
      }
    }
  }

  return string;
};

export default class I18N {
  /**
   * @locus Anywhere
   * @name I18N
   * @constructor
   * @summary Initialize I18N object with `config`
   * @param config                    {Object}
   * @param config.i18n               {Object}  - Internalization object
   * @param config.returnKey          {Boolean} - Return key if l10n value not found
   * @param config.helperName         {String}  - Template main i18n helper name
   * @param config.helperSettingsName {String}  - Template i18nSettings helper name
   */
  constructor(config = {}) {
    check(config, Object);

    let key;
    const self = this;
    this.returnKey = config.returnKey || true;
    this.helperName = config.helperName === null
        ? null
        : config.helperName || 'i18n';
    this.currentLocale = new ReactiveVar(void 0);
    this.helperSettingsName = config.helperSettingsName === null
      ? null
      : config.helperSettingsName || 'i18nSettings';

    check(this.returnKey, Boolean);
    check(this.helperName, Match.OneOf(String, null));
    check(this.helperSettingsName, Match.OneOf(String, null));
    check(config.i18n, Object);

    this.locales = [];
    this.strings = {};

    this.addl10n(config.i18n);

    if (isObject(config.i18n)) {
      check(config.i18n.settings, Object);
      this.settings = config.i18n.settings;
      this.defaultLocale = this.settings.defaultLocale;
      check(this.defaultLocale, String);
      this.strings['__settings.__langSet__'] = [];
      this.strings['__settings.__langConfig__'] = [];
      const dotted = toDottedString.call(this, this.settings, '__settings');

      for (key in dotted) {
        if (typeof dotted[key] === 'string') {
          this.strings[key] = dotted[key];
        }
      }

      for (key in this.settings) {
        if (this.settings[key]?.code) {
          this.locales.push(key);
          this.strings['__settings.__langSet__'].push(this.settings[key].code);
          this.strings['__settings.__langConfig__'].push(this.settings[key]);
        }
      }
    }

    this.userLocale = ((Meteor.isClient) ? window.navigator.userLanguage || window.navigator.language || navigator.userLanguage : this.settings.defaultLocale);

    if (Meteor.isClient) {
      if (typeof Template !== 'undefined' && Template !== null) {
        if (this.helperName !== null) {
          /**
           * @summary Main `i18n` template helper
           */
          Template.registerHelper(this.helperName, function () {
            return self.get.apply(self, arguments);
          });
        }

        if (this.helperSettingsName !== null) {
          /**
           * @summary Settings `i18n` template helper, might be used to build language switcher (see demo folder).
           */
          Template.registerHelper(this.helperSettingsName, function () {
            return self.getSetting.apply(self, arguments);
          });
        }
      }

      const savedLocale = clientStorage.get('___i18n.locale___');
      if (!this.currentLocale.get()) {
        if (!savedLocale) {
          for (let lang of this.strings['__settings.__langConfig__']) {
            if (lang.code === this.userLocale || lang.isoCode === this.userLocale) {
              this.currentLocale.set(lang.code);
              clientStorage.set('___i18n.locale___', lang.code);
              break;
            }
          }
        } else {
          if (this.strings['__settings.__langSet__'].includes(savedLocale)) {
            this.currentLocale.set(savedLocale);
          } else {
            this.currentLocale.set(this.defaultLocale);
            clientStorage.set('___i18n.locale___', this.defaultLocale);
          }
        }
      }
    } else {
      this.defaultLocale = this.settings.defaultLocale;
      this.currentLocale.set(this.defaultLocale);
    }

    if (!this.currentLocale.get()) {
      this.currentLocale.set(this.defaultLocale);
      clientStorage.set('___i18n.locale___', this.defaultLocale);
    }
  }

  /**
   * @locus Anywhere
   * @memberOf I18N
   * @name get
   * @summary Get l10n value by key
   * @param locale       {String} - [Optional] Two-letter locale string
   * @param key          {String} - l10n key like: `folder.file.object.key`
   * @param replacements... {String|[String]|Object} - [Optional] Replacements for placeholders in l10n string
   */
  get(...args) {
    let key;
    let lang;
    let replacements;

    if (!args.length || !args[0] || typeof args[0] !== 'string') {
      return '';
    }

    if (!!~this.locales.indexOf(args[0])) {
      lang = args[0];
      key = args[1];
      replacements = args.slice(2);
    } else {
      lang = this.currentLocale.get() || this.defaultLocale || 'en';
      key = args[0];
      replacements = args.slice(1);
    }

    if (lang) {
      const _key = `${lang}.${key}`;
      let result = (this.strings && this.strings[_key] ? this.strings[_key] : undefined) || (this.returnKey ? _key : '');

      if (typeof result === 'function') {
        result = result.call(this);
      }

      if ((result !== _key) && result && result.length && Object.keys(replacements?.[0]?.hash || replacements).length) {
        result = proceedPlaceholders(result, replacements);
      }

      return result;
    }

    return this.returnKey ? key : '';
  }

  /**
   * @locus Anywhere
   * @memberOf I18N
   * @name has
   * @summary Check if key exists in current locale
   * @param locale       {String} - [Optional] Two-letter locale string
   * @param key          {String} - l10n key like: `folder.file.object.key`
   */
  has(...args) {
    let key;
    let lang;

    if (!args.length || !args[0]) {
      return '';
    }

    if (this.locales.includes(args[0])) {
      lang = args[0];
      key = args[1];
    } else {
      lang = this.currentLocale.get() || this.defaultLocale || 'en';
      key = args[0];
    }

    if (lang) {
      key = `${lang}.${key}`;
      return !!(this.strings?.[key] ? this.strings[key] : undefined);
    }

    return false;
  }

  /**
   * @locus Anywhere
   * @memberOf I18N
   * @name setLocale
   * @summary Set another locale
   * @param locale {String} - Two-letter locale string
   */
  setLocale(locale) {
    check(locale, String);

    if (this.settings && this.settings[locale]) {
      this.currentLocale.set(locale);
      if (Meteor.isClient) {
        clientStorage.set('___i18n.locale___', locale);
      }
    } else {
      throw new Meteor.Error(404, `No such locale: \"${locale}\"`);
    }
    return this;
  }

  /**
   * @locus Anywhere
   * @memberOf I18N
   * @name getSetting
   * @summary Get parsed data by key from i18n.json file
   * @param key {String} - One of the keys: 'current', 'all', 'other', 'locales'
   */
  getSetting(key) {
    check(key, Match.Optional(Match.OneOf('current', 'all', 'other', 'locales', 'currentISO', 'currentName')));
    if (key) {
      return this.langugeSet()[key] || undefined;
    }
    return this.langugeSet();
  }

  /**
   * @locus Anywhere
   * @memberOf I18N
   * @name langugeSet
   * @summary Get data from i18n config
   */
  langugeSet() {
    let key;
    const locale = this.currentLocale.get();
    return {
      current: locale,
      currentISO: this.settings[locale].isoCode,
      currentName: this.settings[locale].name,
      all: (() => {
        const result = [];
        for (key in this.settings) {
          if (isObject(this.settings[key])) {
            result.push(this.settings[key]);
          }
        }
        return result;
      })(),
      other: (() => {
        const result = [];
        for (key in this.settings) {
          if (isObject(this.settings[key]) && (key !== locale)) {
            result.push(this.settings[key]);
          }
        }
        return result;
      })(),
      locales: (() => {
        const result = [];
        for (key in this.settings) {
          if (isObject(this.settings[key])) {
            result.push(this.settings[key].code);
          }
        }
        return result;
      })()
    };
  }

  /**
   * @locus Anywhere
   * @memberOf I18N
   * @name addl10n
   * @summary add l10n data
   * @example { en: { newKey: "new data" } }
   */
  addl10n(l10n) {
    check(l10n, Object);

    let k;
    let key;
    let object;
    for (key in l10n) {
      if (key !== 'settings') {
        object = toDottedString.call(this, l10n[key], key);
        for (k in object) {
          if (typeof object[k] === 'string') {
            this.strings[k] = object[k];
          }
        }
      }
    }
  }
}
