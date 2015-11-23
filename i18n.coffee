#################
# Helpers
# Local scope
#################

if Meteor.isServer
  fs    = Npm.require "fs-extra"
  bound = Meteor.bindEnvironment (callback) -> callback()

###
@locus Anywhere
@name  hashCode
@description Fast lightweight non-cryptographic hash function
###
hashCode = (s) ->
  s.split('').reduce ((a, b) ->
    a = (a << 5) - a + b.charCodeAt(0)
    a & a
  ), 0

###
@locus Anywhere
@name  toDottedString
@description Convert object nested keys into dotted string
###
toDottedString = (obj, prepend = 'i18n') ->
  check obj, Object
  check prepend, String

  final = {}
  for key, value of obj
    if _.isString value
      final[prepend + '.' + key] = value
    else
      final = _.extend final, toDottedString value, prepend + '.' + key
  return final

###
@locus Anywhere
@name  proceedPlaceholders
@description Replace placeholders with replacements in l10n strings
###
proceedPlaceholders = (string, replacements) ->
  check string, Match.Optional String

  if string
    for replacement in replacements
      if _.isObject replacement?.hash
        for key, value of replacement.hash
          string = string.replace new RegExp("\{\{(\s)*(#{key})+(\s)*\}\}", 'i'), value
      else if _.isObject replacement
        for key, value of replacement
          string = string.replace new RegExp("\{\{(\s)*(#{key})+(\s)*\}\}", 'i'), value
      else
        string = string.replace new RegExp('\{\{(\s)*([A-z])+(\s)*\}\}', 'i'), replacement
  return string

###
@locus Anywhere
@name  getI18nFiles
@description Scan i18n directory for l10n files
###
getI18nFiles = (path) ->
  check path, String

  _self = @
  fs.readdir path, (err, list) ->
    if list
      list.forEach (file) ->
        file = "#{path}#{file}"

        fs.stat file, (err, stat) -> bound ->
          if stat and stat.isDirectory()
            getI18nFiles.call _self, file
          else
            if !!~file.indexOf '.json'
              fcont = fs.readJsonSync file
              for skey, svalue of toDottedString fcont, file.replace('.json', '').replace(_self.path + '/', '').replace(/\/\//g, '.').replace(/\//g, '.')
                _self.collection.upsert {key: skey}, {value: svalue, key: skey}


class I18N
  ###
  @locus Anywhere
  @class I18N
  @constructor 
  @description Initialize I18N object with `config`
  @param config                    {Object}
  @param config.path               {String}  - Path to `i18n` folder
  @param config.returnKey          {Boolean} - Return key if l10n value not found
  @param config.collectionName     {String}  - i18n Collection name
  @param config.helperName         {String}  - Template helper name
  @param config.helperSettingsName {String}  - Settings helper name
  @param config.allowPublishAll    {Boolean} - Allow publish full i18n set to client
  ###
  constructor: (config = {}) ->
    check config, Object

    _self               = @
    @returnKey          = config.returnKey or true
    @helperName         = config.helperName or 'i18n'
    @collectionName     = config.collectionName or "internalization"
    @allowPublishAll    = config.allowPublishAll or true
    @helperSettingsName = config.helperName or 'i18nSettings'
    @path               = config.path or '/assets/app/i18n'

    check @returnKey, Boolean
    check @helperName, String
    check @collectionName, String
    check @allowPublishAll, Boolean
    check @helperSettingsName, String

    @collection         = new Meteor.Collection @collectionName
    @currentLocale       = new ReactiveVar undefined

    if Meteor.isClient
      @strings        = {}
      @subscribedKeys = new ReactiveVar ['__settings.defaultLocale', '__settings.__langSet__', '__settings.__langConfig__']
      @strings[key]   = new ReactiveVar([]) for key in ['__settings.__langSet__', '__settings.__langConfig__']
      ###
      @description Main `i18n` template helper
      ###
      Template.registerHelper @helperName, => 
        args = Array.prototype.slice.call arguments
        args.push true
        @get.apply @, args

      ###
      @description Settings `i18n` template helper, might be used to build language switcher (see demo folder).
      ###
      Template.registerHelper @helperSettingsName, => @getSetting.apply @, arguments

      Meteor.subscribe '___i18n___', @subscribedKeys.get(), ->
        for key in _self.subscribedKeys.get()
          _self.strings[key] = new ReactiveVar(if _self.returnKey then key else '') unless _self.strings?[key]
          _self.strings[key].set _self.collection.findOne({key})?.value
        
        _self.defaultLocale = _self.collection.findOne({key: '__settings.defaultLocale'})?.value

        unless _self.currentLocale.get()
          unless ClientStorage.get "___i18n.locale___"
            for lang in _self.collection.findOne({key: '__settings.__langConfig__'})?.value or []
              if lang.code is _self.userLocale
                _self.currentLocale.set lang.code
                ClientStorage.set "___i18n.locale___", lang.code
              if lang.isoCode is _self.userLocale
                _self.currentLocale.set lang.isoCode.substring 0, 2
                ClientStorage.set "___i18n.locale___", lang.isoCode.substring 0, 2

            _self.currentLocale.set _self.defaultLocale
            ClientStorage.set "___i18n.locale___", _self.defaultLocale
          else
            if !!~(_self.collection.findOne({key: '__settings.__langSet__'})?.value or []).indexOf ClientStorage.get "___i18n.locale___"
              _self.currentLocale.set ClientStorage.get "___i18n.locale___"
            else
              _self.currentLocale.set _self.defaultLocale
              ClientStorage.set "___i18n.locale___", _self.defaultLocale

    else
      @path = Meteor.rootPath + @path
      throw new Meteor.Error 404, "[i18n | ostrio:i18n] Configuration file: \"#{@path}/i18n.json\" not found!" if not fs.existsSync "#{@path}/i18n.json"

      @collection._ensureIndex {key: 1}, {background: true, unique: true}
      @collection.deny
        insert: -> true
        update: -> true
        remove: -> true

      @settings = fs.readJsonSync "#{@path}/i18n.json", encoding: "utf8"
      @collection.upsert {key: '__settings.__langSet__'}, {value: [], key: '__settings.__langSet__'}
      @collection.upsert {key: '__settings.__langConfig__'}, {value: [], key: '__settings.__langConfig__'}

      for key, value of @settings
        if value?.path
          getI18nFiles.call @, "#{@path}/#{value.path.replace('i18n', '').replace('i18n/', '').replace('/i18n', '').replace('/i18n/', '').replace(/^\//, '')}"

        if value?.code
          @collection.update {key: '__settings.__langSet__'}, {$addToSet: value: value.code}
          @collection.update {key: '__settings.__langConfig__'}, {$addToSet: value: value}

      for skey, svalue of toDottedString @settings, '__settings'
        @collection.upsert {key: skey}, {value: svalue, key: skey}
      
      Meteor.publish '___i18n___', (keys) ->
        check keys, [String]
        _self.collection.find key: $in: keys

      Meteor.publish '___i18nAll___', -> _self.collection.find {} if @allowPublishAll
    
      @defaultLocale = @settings.defaultLocale

    @userLocale = (if (Meteor.isClient) then window.navigator.userLanguage or window.navigator.language or navigator.userLanguage else @settings.defaultLocale)
    
    @currentLocale.set @defaultLocale unless @currentLocale.get()

    if Meteor.isClient
      Tracker.autorun =>
        Meteor.subscribe '___i18n___', @subscribedKeys.get(), ->
          for key in _self.subscribedKeys.get()
            _self.strings[key] = new ReactiveVar(if _self.returnKey then key else '') unless _self.strings?[key]
            _self.strings[key].set _self.collection.findOne({key})?.value or if _self.returnKey then key else ''

  ###
  @locus Client
  @class I18N
  @name  subscribeToAll
  @description Subscribe to full all languages and all l10n props
  @param callback {Function} - Callback function triggered right after subscription is ready
  ###
  subscribeToAll: if Meteor.isClient then (callback) ->
    if @allowPublishAll
      _self = @
      Meteor.subscribe '___i18nAll___', -> 
        i18nSet = _self.collection.find()
        i18nSet.forEach (row) ->
          _self.strings[row.key] = new ReactiveVar(if _self.returnKey then row.key else '') unless _self.strings?[row.key]
          _self.strings[row.key].set row.value if row?.value
        callback && callback()
  else undefined

  ###
  @locus Anywhere
  @class I18N
  @name  get
  @description Get l10n value by key
  @param locale       {String} - [Optional] Two-letter locale string
  @param key          {String} - l10n key like: `folder.file.object.key`
  @param replacements... {String|[String]|Object} - [Optional] Replacements for placeholders in l10n string
  ###
  get: ->
    args = Array.prototype.slice.call arguments

    if !!~args[0].indexOf '.'
      lang         = @currentLocale.get()
      key          = args[0]
      replacements = args.slice 1
    else
      lang         = args[0]
      key          = args[1]
      replacements = args.slice 2

    if replacements[replacements.length] is true
      fromJS = false
    else
      fromJS = true

    if lang
      _key = lang + '.' + key
      key  = lang + '.' + key

      if Object.keys(replacements[0]?.hash or replacements)?.length
        key = key + '__--__' + hashCode(JSON.stringify(replacements))

      if Meteor.isClient
        @strings[_key] = new ReactiveVar(if @returnKey then _key else '') unless @strings?[_key]
        sk = @subscribedKeys.get()
        if !~sk.indexOf _key
          sk.push _key
          @subscribedKeys.set sk

        unless Object.keys(replacements[0]?.hash or replacements)?.length
          result =  @strings[_key].get()
        else
          _self = @
          @strings[key] = new ReactiveVar(if @returnKey then _key else '') unless @strings?[key]
          @strings[key].get = ->
            if Tracker.active or fromJS
              @dep.depend()
              return proceedPlaceholders _self.strings[_key].get(), replacements
          result =  @strings[key].get()
      else
        result = @collection.findOne({key: _key})?.value
        if Object.keys(replacements[0]?.hash or replacements)?.length
          result = proceedPlaceholders result, replacements

      return if Meteor.isClient then result else if not result and @returnKey then _key else if not result then '' else result

  ###
  @locus Anywhere
  @class I18N
  @name  setLocale
  @description Set another locale
  @param locale {String} - Two-letter locale string
  ###
  setLocale: (locale) ->
    check locale, String

    if (if Meteor.isClient then !!~@strings['__settings.__langSet__'].get()?.indexOf(locale) else @settings?[locale])
      @currentLocale.set locale
      ClientStorage.set "___i18n.locale___", locale if Meteor.isClient 
    else
      throw new Meteor.Error 404, "No such locale: \"#{locale}\""
    return @

  ###
  @locus Anywhere
  @class I18N
  @name  getSetting
  @description Get parsed data by key from i18n.json file
  @param key {String} - One of the keys: 'current', 'all', 'other', 'locales'
  ###
  getSetting: (key) ->
    check key, Match.Optional Match.OneOf 'current', 'all', 'other', 'locales'

    if key
      return @langugeSet()?[key]
    else
      return @langugeSet()

  ###
  @locus Anywhere
  @class I18N
  @name  langugeSet
  @description Get parsed datafrom i18n.json file
  ###
  langugeSet: ->
    if Meteor.isClient
      current: @currentLocale.get()
      all: @get '__settings', '__langConfig__'
      other: (set for set in @get '__settings', '__langConfig__' when set.code isnt @currentLocale.get())
      locales: @get '__settings', '__langSet__'
    else
      current: @currentLocale.get()
      all: (value for key, value of @settings when _.isObject value)
      other: (value for key, value of @settings when _.isObject(value) and key isnt @currentLocale.get())
      locales: (value.code for key, value of @settings when _.isObject value)