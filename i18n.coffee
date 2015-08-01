if Meteor.isServer
  ###
  @var {Object} _SampleData - Object with sample i18n data
  ###
  _SampleData = 
    de:
      nestedFolder:
        support:
          nested:
            objects: "zu"

      sample:
        hello: "Hallo"
        userHello: "Hallo {{name}}!"
        fullName: "Vollständige Name des Benutzers ist: {{first}} {{middle}} {{last}}"
        html: "<b>Fettdruck</b>"
        nested:
          objects:
            might:
              be:
                very: "tief"

    en:
      nestedFolder:
        support:
          nested:
            objects: "too"

      sample:
        hello: "Hello"
        userHello: "Hi {{name}}!"
        fullName: "User's full name is: {{first}} {{middle}} {{last}}"
        html: "<b>Bold text</b>"
        nested:
          objects:
            might:
              be:
                very: "deep"

    i18nConfig:
      defaultLocale: "en"
      de:
        code: "de"
        isoCode: "de_DE"
        name: "Deutsch"
        route: "i18n/de/"

      en:
        code: "en"
        isoCode: "en_US"
        name: "English"
        route: "i18n/en/"


  ###
  @var {Object} fs - FileSystem NPM
  @var {Object} bound - Meteor.bindEnvironment aka Fiber wrapper
  ###
  fs = Npm.require "fs-extra"
  bound = Meteor.bindEnvironment (callback) ->
    callback()

###
@class Internalization
@description initialize global object with initial data
###
class Internalization
  ###
  @constructor
  @param {Object} config:
    @property {String}   defaultLocale        - Default application's locale
    @property {String}   currentLocale        - Locale of current application's state
    @property {Boolean}  onWrongKey.returnKey - Return unmatched key to Template or leave it empty
    @property {Boolean}  isReady              - Is everything ready for internalization?
    @property {Boolean}  isStarted            - Is internalization service started?
    @property {Object}   config               - Object with internalization configuration data
    @property {String}   storagePath          - Path where i18n files is placed
    @property {Mongo.Collection} internalizationCollection - MongoDB Collection Object
  ###
  constructor: (config) ->
    {@defaultLocale, @currentLocale, @onWrongKey, @config, @internalizationCollection, @storagePath} = config if config
    @defaultLocale  ?= "en"
    @currentLocale  ?= "en"
    @onWrongKey     ?= returnKey: true
    @config         ?= {}
    @storagePath    ?= "/assets/app/i18n"
    @internalizationCollection ?= new Meteor.Collection "__internalization__"
    @isReady    = false
    @isStarted  = false
    @dataTypes  = [ "localizations", "config" ]

    ###
    @var {Object} _l10n - Object with current localization data
    @var {Object} _Localizations - Object with all internalization data
    @description Used to concentrate all internalization data
    ###
    @_l10n = {}
    @_Localizations = {}
    @_Strings = {}

    if Meteor.isServer
      @internalizationCollection.deny
        insert: ->
          true
        update: ->
          true
        remove: ->
          true

      Meteor.publish @internalizationCollection._name, =>
        console.log "p[ublish", @internalizationCollection._name
        @internalizationCollection.find {}
        ,
          fields:
            value: 1
            type: 1

      ###
      @property {String} storagePath- Storage dir /i18n/ directory
      @property {String} path       - Path to current /i18n/ directory
      @property {Object} files      - Object with all found files under #path directory
      ###
      @path      = Meteor.rootPath + @storagePath
      @files     = {}

      configFileExists = fs.existsSync "#{@path}/i18n.json"
      @isReady = true if not configFileExists and not _.isEmpty(@config)

      if _.isEmpty(@config) and not configFileExists

        fs.mkdirsSync "#{@path}/de/nested/folder", 0o0750
        fs.mkdirsSync "#{@path}/en/nested/folder", 0o0750
        fs.writeJSONSync "#{@path}/de/nested/folder/is.json", _SampleData.de.nestedFolder
        fs.writeJSONSync "#{@path}/en/nested/folder/is.json", _SampleData.en.nestedFolder
        fs.writeJSONSync "#{@path}/de/sample.json", _SampleData.de.sample
        fs.writeJSONSync "#{@path}/en/sample.json", _SampleData.en.sample
        fs.writeJSONSync "#{@path}/i18n.json", _SampleData.i18nConfig

      Meteor.setInterval =>
        console.log @internalizationCollection.find({}).fetch()
      ,
        30000

      ###
      @description Run i18n.init() function
                   with default path to i18n/ folder
      ###
      @init @path

    else
      ###
      @description Subscribe to i18n collection, call i18n.init on connection callback
      ###
      Meteor.subscribe @internalizationCollection._name, =>
        console.log "subscibe", @internalizationCollection._name

        @loadConfig()
        @init @defaultLocale unless @isStarted


  ###
  @function
  @namespace i18n
  @property locale {function}
  @description Get current localization at any environment
  @return {String} - Locale as reactive data source
  ###
  locale: -> if Meteor.isServer then @currentLocale else Session.get 'i18nCurrentLocale'

  ###
  @function
  @name loadLocalizations
  @description Load localization files into @_Localizations property
  @param {string} locale - Two letter locale code
  ###
  loadLocalizations: (locale) ->
    @_Localizations = @internalizationCollection.findOne(type: "localizations").value
    reactivateObject @_Localizations
    @_Localizations[locale] if locale


  ###
  @namespace i18n
  @property {string} userLocale - User's browser locale
            Detect user's browser locale
  ###
  userLocale: (if (Meteor.isClient) then window.navigator.userLanguage or window.navigator.language or navigator.userLanguage else @defaultLocale)


  ###
  @function
  @name loadConfig
  @description Load configuration object into i18n.config property
  ###
  loadConfig: ->
    @config = @internalizationCollection.findOne(type: "config").value
    @isReady = true
    @config


    ###
  @function
  @namespace i18n
  @property {function} setLocale - Set locale (by ISO code)
  @description Set new locale if it is configured in /private/i18n/i18n.json config file.
               Update session's and localStorage or cookie (via Meteor.storage) dependencies
  @param {string} locale - Two letter locale code
  ###
  setLocale: if Meteor.isClient then (locale) ->

    if @isStarted

      if @_Localizations[locale]
        @currentLocale = locale
        Meteor.storage.set "locale", locale
        Session.set "i18nCurrentLocale", locale
        i18nConfigArray = []
        for key of @_Localizations
          i18nConfigArray.push
            name: key
            value: @config[key]
            currentLocale: locale
        Session.set "i18nConfig", i18nConfigArray
      else if @_Localizations[@config.defaultLocale]
        @setLocale @config.defaultLocale
      else

        throwError 404, locale
    else
      @init locale
    @currentLocale
  else undefined
  
  ###
  @function
  @namespace i18n
  @property {function} init - Run core functions continuous order
  @param    {String}   path - Path to i18n/ folder on server
  ###
  init: if Meteor.isServer then (path) ->

    @path = removeTrailingSlash path if path
    @fillObjectFromDB =>
      # @defineReactivities =>
      @traverseI18nFiles @path
      @getConfigFile()
      @updateRecords()

  else (defaultLocale) ->

    if @isReady and not @isStarted
      userLocale = @userLocale.split("-")[0]
      @loadLocalizations()

      if defaultLocale and @config[defaultLocale]
        @defaultLocale = defaultLocale
      else if @config.defaultLocale
        @defaultLocale = @config.defaultLocale
      else

        throwError 404, defaultLocale

      Meteor.storage.set "locale", (if (Meteor.storage.get("locale")) then Meteor.storage.get("locale") else (if (@config[userLocale]) then userLocale else @defaultLocale))
      @isStarted = true
      @setLocale Meteor.storage.get("locale")
    else unless @isReady
      Meteor.setTimeout =>

        @init @defaultLocale
      , 100


  ###
  @function
  @name onFileChange
  @description Run update functions in continuous order
  ###
  onFileChange: (file) ->
    @getConfigFile()
    @readFile file

  
  # ###
  # @function
  # @name defineReactivities
  # @description set defineReactiveProperty() on each
  #              property from i18n.dataTypes array
  # @param {function} callback - Callback function
  # ###
  # defineReactivities: (callback) ->
  #   @dataTypes.forEach (data) =>
  #     Object.defineReactiveProperty @, data, {}, null, null, =>
  #       bound =>
  #         @updateRecords()

  #   callback() if callback

  
  ###
  @function
  @name fillObjectFromDB
  @description check DB records and fill initial object with it  
  @param {function} callback - Callback function
  ###
  fillObjectFromDB: (callback) ->
    @dataTypes.forEach (data) =>
      row = @internalizationCollection.findOne(type: data)
      if row and JSON.stringify(row.value) isnt JSON.stringify(@[data])
        @[data] = row.value
        @[data]._id = row._id

    callback() if callback

  
  ###
  @function
  @name updateRecords
  @description check DB records and fill initial object with it
  @param {Object} selector - MongoDB selector object
  @param {mix}    value    - Value to write into MongoDB
  ###
  updateRecords: ->
    @internalizationCollection.upsert
      type: "localizations"
    ,
      $set:
        value: @_Localizations
        type: "localizations"

    @internalizationCollection.upsert
      type: "config"
    ,
      $set:
        value: @config
        type: "config"


  ###
  @function
  @name pathToObj
  @description Parse provided path into nested object
  @param {String}   path     - Path to valid destination or file on server
  @param {function} callback - Callback function with one parameter - final object prepared from path
  @callback(localI18n)
  ###
  pathToObj: (path, callback) ->
    path = path.replace "#{@path}/", ""
    path = removeTrailingSlash path
    pathArray = path.split "/"
    localI18n = @_Localizations
    i = 0

    _.each pathArray, (pathPart, i) =>

      if !!~pathPart.indexOf "."
        unless localI18n[pathPart]
          @addProperty localI18n, pathPart, (res) ->
            localI18n = res
            addProperty localI18n, pathArray[i + 1]  if i + 1 < pathArray.length
        else
          localI18n = localI18n[pathArray[i]]
          @addProperty localI18n, pathArray[i + 1]  if i + 1 < pathArray.length
    callback(localI18n) if callback

  
  ###
  @function
  @name addProperty
  @description Create new property and assign empty object to it
  @param {Object}   obj      - Object we're working with
  @param {String}   property - Name of new property
  @param {function} callback - Callback function with one parameter - new empty object
  @callback(obj[property])
  ###
  addProperty: (obj, property, callback) ->
    property = property.replace(".json", "")
    unless obj[property]
      obj[property] = {}
      # Object.defineReactiveProperty obj, property, {}, null, null, =>
      #   bound =>
      #     @updateRecords()

    callback(obj[property]) if callback
  
  ###
  @function
  @name traverseI18nFiles
  @description Walk thought all i18n files
               and store 'em into variable
  @param {String}   path     - Path we are working in
  @param {function} callback - Callback function with two parameters - error, final object
  @callback(error, object)
  ###
  traverseI18nFiles: if Meteor.isServer then (path, callback) ->

    fs.readdir path, (err, list) =>
      bound =>
        # return callback(err) if err and callback
        # pending = list.length
        # return callback(null, @_Localizations) if not pending and callback
        if list
          _.each list, (file) =>
            file = "#{path}/#{file}"

            fs.stat file, (err, stat) =>
              if stat and stat.isDirectory()
                @pathToObj file, =>
                  @traverseI18nFiles file
                    # callback null, @_Localizations if not --pending and callback
              else
                if !!~file.indexOf ".json"
                  @pathToObj file, =>
                    @readFile file

              # callback null, @_Localizations if not --pending and callback
  else undefined


  ###
  @function
  @name readFile
  @description Read file and add it's contents
               into localI18n variable which linked to @_Localizations object
  @param {String}   file     - Path to existing file
  @param {function} callback - Callback function with one parameter - localI18n - the last object we write to
  @callback(error, object)
  ###
  readFile: (file) ->
    localI18n = @_Localizations
    filenames = file.replace("#{@path}/", "").split "/"

    _.each filenames, (filename, i) =>
      bound =>
        # filename = filename.split('.')[0] if !~filename.indexOf '.json'

        if filename isnt "i18n.json"
          if !!~filename.indexOf ".json"
            @watchPathChanges file
            localI18n = localI18n[filename] 
          else
            localI18n[filename.split('.')[0]] = fs.readJsonSync file, encoding: "utf8"
            # if localI18n[filename]
            # else
            #   localI18n[filename] = {}
            #   localI18n = localI18n[filename]
    # @updateRecords()

  
  # ###
  # @function
  # @name getFile
  # @description Read file and callback it's data
  # @param {String} file       - Full path to file on server
  # @param {array}  filenames  - Array of folders names
  # @param {number} index      - Index of working directory from Filenames Array
  # @param {Object} li18n      - Linked object to @_Localizations property
  # @param {function} callback - Callback function with four parameters - file contents, filenames, index, li18n
  # @callback(data, filenames, index, li18n)
  # ###
  # getFile: (file) ->

  #   return fs.readJsonSync file,
  #     encoding: "utf8"


  ###
  @function
  @name getConfigFile
  @description Read /i18n.json file contents,
               store it in variable and set watcher on it
  ###
  getConfigFile: if Meteor.isServer then ->

    @watchPathChanges "#{@path}/i18n.json"
    data = fs.readJsonSync "#{@path}/i18n.json",
      encoding: "utf8"
    _.each data, (lang, key) =>
      bound =>
        @_Localizations[key] = {} if key.length is 2

    @config = data
    @isStarted = true
    @isReady = true
  else undefined


  ###
  @function
  @name watchPathChanges
  @description Correctly setting watcher on files or directories
               If watcher already is set - remove it
               If watcher is not set - set it and store fs.FSWatcher
  @param {String} path - Full path to file or folder on server
  ###
  watchPathChanges: (path) ->
    unless @files[path]
      @files[path] = {}
      @files[path].onWatch = false
    if @files[path].onWatch is false
      @files[path].onWatch = true
      @files[path].watcher = fs.watch path, =>
        @onFileChange path
    else
      if @files[path].watcher
        @files[path].watcher.close()
        @files[path].watcher = null
        @files[path].onWatch = false
        @watchPathChanges path


  ###
  @function
  @namespace i18n
  @property {function} get          - Get values, and do pattern replaces from current localization
  @param    {String}   locale       - Two-letter localization code
  @param    {String}   param        - string in form of dot notation, like: folder1.folder2.file.key.key.key... etc.
  @param    {mix}      replacements - Object, array, or string of replacements
  ###
  get: () ->
    if Meteor.isServer
      if @isReady and @isStarted
        if arguments[0] and !!~arguments[0].indexOf '.'
          locale = @currentLocale or @defaultLocale
          param = arguments[0]
          xStart = 1
        else
          locale = arguments[0]
          param = arguments[1]
          xStart = 2

        if locale and param
          if arguments.length is xStart + 1 and (not arguments[xStart + 2] or _.isFunction(arguments[xStart + 2]))
            if _.isFunction arguments[xStart]
              cb = arguments[xStart]
            else
              replacements = arguments[xStart]
          else if arguments.length >= xStart + 1
            x = xStart
            replacements = []
            while arguments.length >= x + 1
              if _.isFunction arguments[x]
                cb = arguments[x]
              else
                replacements.push arguments[x]
              x++

          splitted = param.split '.'

          deepen = (obj, keypath, index=0) ->
            if obj and keypath[index]
              key = keypath[index]
              if obj[key]
                value = obj[key]
                if _.isObject(value) then deepen value, keypath, index + 1 else value
              else
                return if @onWrongKey.returnKey then param else ""
            else
               return if @onWrongKey.returnKey then param else ""

          @_l10n["#{locale}.#{param}"] = deepen.call @, @_Localizations[locale], splitted
          if replacements and (_.isObject(replacements) or _.isString(replacements) or _.isArray(replacements))
            postfix = SHA256 param + JSON.stringify(replacements)

            if not @_l10n["#{locale}.#{param}#{postfix}"]
              @renderString param, replacements, postfix
            
            cb null, true if cb
            return @_l10n["#{locale}.#{param}#{postfix}"]

          else
            cb null, true if cb
            return @_l10n["#{locale}.#{param}"]

        else
          cb null, true if cb
          return ''

      else unless @isReady
        ticker = ''
        Meteor.wrapAsync((params, cb) =>
          ticker = Meteor.setInterval =>
            params = _.values(params)
            params.push cb
            @get.apply @, params
            Meteor.clearInterval ticker
          , 100
        )(arguments)
        return @_l10n["#{locale}.#{param}"] or ''
    else
      if arguments[0] and !!~arguments[0].indexOf '.'
        locale = Session.get "i18nCurrentLocale"
        param = arguments[0]
        xStart = 1
      else
        locale = arguments[0]
        param = arguments[1]
        xStart = 2
      
      if not _.has @_l10n, "#{locale}.#{param}"
        return if @onWrongKey.returnKey then param else ""

      if arguments.length is xStart + 1
        if arguments[xStart].hash
          replacements = arguments[xStart].hash
        else
          replacements = arguments[xStart]
      else if arguments.length > xStart + 1
        x = xStart
        replacements = []
        while arguments.length >= x + 1
          if arguments[x] instanceof Spacebars.kw
            replacements = arguments[x].hash if not _.isEmpty arguments[x].hash
          else
            replacements.push arguments[x]
          x++
          
      if replacements and not _.isEmpty replacements
        postfix = SHA256 param + JSON.stringify replacements
        if not _.has @_Strings, "#{locale}.#{param}#{postfix}"
          @renderString param, replacements, postfix
        return @_l10n["#{locale}.#{param}#{postfix}"]

      else
        return @_l10n["#{locale}.#{param}"]

  ###
  @function
  @name renderString
  @description Render string - replace Handlebars placeholders by values

  @param {String}  property        - Name of property in @_l10n object
  @param {mix}     replacements    - Object, array, or string of replacements
  @param {String}  postfix         - Unique postfix, appended to property string

  @BUG: Does not returns values on Live-updates without timeout, but if you go by routes
  @TODO: Debug bug
  ###
  renderString: (property, replacements, postfix) ->
    if Meteor.isServer
      for key of @config
        if _.isObject @config[key]
          rendered = @_l10n["#{@config[key].code}.#{property}"]
          if rendered
            matches = rendered.match(/\{{(.*?)\}}/g)
            if matches and replacements
              if _.isString replacements
                i = matches.length - 1
                while i >= 0
                  rendered = rendered.replace matches[i], replacements
                  i--
              else
                i = matches.length - 1
                while i >= 0
                  rendered = renderReplace rendered, replacements, matches, i
                  i--
            @_l10n["#{@config[key].code}.#{property}#{postfix}"] = rendered
    else
      for key of @config
        if _.isObject @config[key]
          rendered = @_l10n["#{@config[key].code}.#{property}"]
          if rendered
            matches = rendered.match(/\{{(.*?)\}}/g)
            if matches and replacements
              if _.isString replacements
                rendered = rendered.replace matches[0], replacements
              else
                i = matches.length - 1
                while i >= 0
                  rendered = renderReplace rendered, replacements, matches, i
                  i--
            defineReactiveProperyWrapper @_l10n, "#{@config[key].code}.#{property}#{postfix}", rendered