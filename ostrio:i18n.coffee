###
@namespace i18n
@description initialize global object
@global
###
@i18n = 
  ###
  @namespace i18n
  @property {string}   defaultLocale     - Default application's locale
  @property {string}   currentLocale     - Locale of current application's state
  @property {bool}     isReady           - Is everything ready for internalization?
  @property {bool}     isStarted         - Is internalization service started?
  @property {object}   l10n              - Object with current localization data
  @property {object}   config            - Object with internalization configuration data
  @property {object}   localizations     - Object with all internalization data
  ###
  defaultLocale: "en"
  currentLocale:  "en"
  onWrongKey:
    returnKey: true
  isReady: false
  isStarted: false
  config: {}
  internalizationCollection: new Meteor.Collection "internalization"

_l10n = {}
_Localizations = {}


if Meteor.isServer
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


  fs = Npm.require "fs-extra"
  bound = Meteor.bindEnvironment (callback) ->
    callback()
  
  ###
  @namespace i18n
  @property {array}  dataTypes  - Array of file types
  @property {string} storageDir - Path to current /i18n/ directory, chosen according to environment
  @property {string} path       - Path to current /i18n/ directory, chosen according to environment
  @property {object} files      - Object with all found files under #path directory
  ###
  i18n.dataTypes = [ "localizations", "config" ]
  i18n.storageDir = (if (process.env.NODE_ENV is "development") then "/private/i18n" else "/builded/bundle/programs/server/assets/app/i18n")
  i18n.path = process.env.PWD + i18n.storageDir
  i18n.files = {}

  if !fs.existsSync "#{i18n.path}/i18n.json"
    fs.mkdirsSync "#{i18n.path}/de/nested/folder", 0o0750
    fs.mkdirsSync "#{i18n.path}/en/nested/folder", 0o0750
    fs.writeJSONSync "#{i18n.path}/de/nested/folder/is.json", _SampleData.de.nestedFolder
    fs.writeJSONSync "#{i18n.path}/en/nested/folder/is.json", _SampleData.en.nestedFolder
    fs.writeJSONSync "#{i18n.path}/de/sample.json", _SampleData.de.sample
    fs.writeJSONSync "#{i18n.path}/en/sample.json", _SampleData.en.sample
    fs.writeJSONSync "#{i18n.path}/i18n.json", _SampleData.i18nConfig

  
  ###
  @namespace i18n
  @property {constructor} internalizationCollection - MongoDB Collection Object
  @constructor
  ###
  i18n.internalizationCollection.deny
    insert: ->
      true

    update: ->
      true

    remove: ->
      true

  
  ###
  @function
  @namespace i18n
  @property {function} init - Run core functions continuous order
  @param    {string}   path - Path to i18n/ folder on server
  ###
  i18n.init = (path) ->
    i18n.path = removeTrailingSlash(path)
    fillObjectFromDB ->
      defineReactivities ->
        traverseI18nFiles i18n.path
        getConfigFile()



  
  ###
  @function
  @name onFileChange
  @description Run update functions in continuous order
  ###
  onFileChange = (file) ->
    getConfigFile()
    readFile file

  
  ###
  @function
  @name defineReactivities
  @description set defineReactiveProperty() on each
               property from i18n.dataTypes array
  @param {function} callback - Callback function
  ###
  defineReactivities = (callback) ->
    i18n.dataTypes.forEach (data) ->
      Object.defineReactiveProperty i18n, data, {}, null, null, ->
        bound ->
          updateRecords()

    callback() if callback

  
  ###
  @function
  @name fillObjectFromDB
  @description check DB records and fill initial object with it  
  @param {function} callback - Callback function
  ###
  fillObjectFromDB = (callback) ->
    i18n.dataTypes.forEach (data) ->
      row = i18n.internalizationCollection.findOne(type: data)
      if row and JSON.stringify(row.value) isnt JSON.stringify(i18n[data])
        i18n[data] = row.value
        i18n[data]._id = row._id

    callback() if callback

  
  ###
  @function
  @name updateRecords
  @description check DB records and fill initial object with it
  @param {object} selector - MongoDB selector object
  @param {mix}    value    - Value to write into MongoDB
  ###
  updateRecords = ->
    i18n.internalizationCollection.upsert
      type: "localizations"
    ,
      value: _Localizations
      type: "localizations"

    i18n.internalizationCollection.upsert
      type: "config"
    ,
      value: i18n.config
      type: "config"


  
  ###
  @function
  @name pathToObj
  @description Parse provided path into nested object
  @param {string}   path     - Path to valid destination or file on server
  @param {function} callback - Callback function with one parameter - final object prepared from path
  @callback
  ###
  pathToObj = (path, callback) ->
    path = path.replace(process.env.PWD, "").replace("#{i18n.storageDir}/", "")
    path = removeTrailingSlash(path)
    pathArray = path.split("/")
    localI18n = _Localizations
    i = 0

    while i < pathArray.length
      if pathArray[i].indexOf(".") is -1
        unless localI18n[pathArray[i]]
          addProperty localI18n, pathArray[i], (res) ->
            localI18n = res
            addProperty localI18n, pathArray[i + 1]  if i + 1 < pathArray.length
          
        else
          localI18n = localI18n[pathArray[i]]
          addProperty localI18n, pathArray[i + 1]  if i + 1 < pathArray.length
      i++
    callback(localI18n) if callback

  
  ###
  @function
  @name addProperty
  @description Create new property and assign empty object to it
  @param {object}   obj      - Object we're working with
  @param {string}   property - Name of new property
  @param {function} callback - Callback function with one parameter - new empty object
  @callback(object)
  ###
  addProperty = (obj, property, callback) ->
    property = property.replace(".json", "")
    unless obj[property]
      obj[property] = {}
      Object.defineReactiveProperty obj, property, {}, null, null, ->
        bound ->
          updateRecords()

    callback(obj[property]) if callback

  
  ###
  @function
  @name removeTrailingSlash
  @description Removes trailing Slash from string if its exists
  @param {string} string - String
  ###
  removeTrailingSlash = (string) ->
    if string.substr(-1) is "/"
      string.substr 0, string.length - 1
    else
      string

  
  ###
  @function
  @name traverseI18nFiles
  @description Walk thought all i18n files
               and store 'em into variable
  @param {string}   path     - Path we are working in
  @param {function} callback - Callback function with two parameters - error, final object
  @callback(error, object)
  ###
  traverseI18nFiles = (path, callback) ->
    fs.readdir path, (err, list) ->
      
        return callback(err) if err and callback
        pending = list.length
        return callback(null, _Localizations)  if not pending and callback

        list.forEach (file) ->
          file = "#{path}/#{file}"

          fs.stat file, (err, stat) ->
            if stat and stat.isDirectory()
              pathToObj file, ->
                traverseI18nFiles file, ->
                  callback null, _Localizations  if not --pending and callback
            else
              if file.indexOf(".json") isnt -1
                pathToObj file, ->
                  readFile file

            callback null, _Localizations  if not --pending and callback
            
      


  ###
  @function
  @name readFile
  @description Read file and add it's contents
               into localI18n variable which linked to _Localizations object
  @param {string}   file     - Path to existing file
  @param {function} callback - Callback function with one parameter - localI18n - the last object we write to
  @callback(error, object)
  ###
  readFile = (file, callback) ->
    localI18n = _Localizations
    filenames = file.replace(process.env.PWD, "").replace("#{i18n.storageDir}/", "").split("/")
    i = 0

    while i < filenames.length
      if filenames[i] isnt "i18n.json"
        if filenames[i].indexOf(".json") > 1
          watchPathChanges file
          getFile file, filenames, i, localI18n, (data, prop, index, li18n) ->
            li18n[prop[index].replace(".json", "")] = JSON.parse(data)
            callback(localI18n) if callback
            

        else
          localI18n = localI18n[filenames[i]]
          callback(localI18n) if callback
      i++

  
  ###
  @function
  @name getFile
  @description Read file and callback it's data
  @param {string} file       - Full path to file on server
  @param {array}  filenames  - Array of folders names
  @param {number} index      - Index of working directory from Filenames Array
  @param {object} li18n      - Linked object to _Localizations property
  @param {function} callback - Callback function with four parameters - file contents, filenames, index, li18n
  @callback(data, filenames, index, li18n)
  ###
  getFile = (file, filenames, index, li18n, callback) ->
    fs.readFile file,
      encoding: "utf8"
    , (err, data) ->
        throw err  if err
        callback data, filenames, index, li18n
      


  
  ###
  @function
  @name getConfigFile
  @description Read /i18n.json file contents,
               store it in variable and set watcher on it
  ###
  getConfigFile = ->
    watchPathChanges "#{i18n.path}/i18n.json"
    fs.readFile "#{i18n.path}/i18n.json",
      encoding: "utf8"
    , (err, data) ->
        throw err  if err
        i18n.config = JSON.parse(data)
        i18n.isStarted = true
        i18n.isReady = true


  
  ###
  @function
  @name watchPathChanges
  @description Correctly setting watcher on files or directories
               If watcher already is set - remove it
               If watcher is not set - set it and store fs.FSWatcher
  @param {string} path - Full path to file or folder on server
  ###
  watchPathChanges = (path) ->
    unless i18n.files[path]
      i18n.files[path] = {}
      i18n.files[path].onWatch = false
    if i18n.files[path].onWatch is false
      i18n.files[path].onWatch = true
      i18n.files[path].watcher = fs.watch path, ->
        onFileChange path
    else
      if i18n.files[path].watcher
        i18n.files[path].watcher.close()
        i18n.files[path].watcher = null
        i18n.files[path].onWatch = false
        watchPathChanges path


  ###
  @function
  @namespace i18n
  @property {function} get          - Get values, and do pattern replaces from current localization
  @param    {string}   locale       - Two-letter localization code
  @param    {string}   param        - string in form of dot notation, like: folder1.folder2.file.key.key.key... etc.
  @param    {mix}      replacements - Object, array, or string of replacements
  ###
  i18n.get = () ->
    if i18n.isReady and i18n.isStarted

      if arguments[0] and arguments[0].indexOf('.') isnt -1
        locale = @currentLocale or @defaultLocale
        param = arguments[0]
        xStart = 1
      else
        locale = arguments[0]
        param = arguments[1]
        xStart = 2

      if locale and param
        if arguments.length is xStart + 1 and (!arguments[xStart + 2] or _.isFunction(arguments[xStart + 2]))
          
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

        deepen = (obj, keypath, index=0)->
          if obj && keypath[index]
            key = keypath[index]
            if obj[key]
              value = obj[key]
              if _.isObject(value) then deepen value, keypath, index + 1 else value
            else
              return if i18n.onWrongKey.returnKey then param else ""
          else
             return if i18n.onWrongKey.returnKey then param else ""

        _l10n["#{locale}.#{param}"] = deepen _Localizations[locale], splitted
        if replacements and (_.isObject(replacements) or _.isString(replacements) or _.isArray(replacements))
          postfix = SHA256 param + JSON.stringify(replacements)

          if !_l10n["#{locale}.#{param}#{postfix}"]
            renderString param, replacements, postfix
          
          cb null, true if cb
          return _l10n["#{locale}.#{param}#{postfix}"]

        else
          cb null, true if cb
          return _l10n["#{locale}.#{param}"]

      else
        cb null, true if cb
        return ''

    else unless i18n.isReady
      ticker = ''
      Meteor.wrapAsync((params, cb)->
        ticker = Meteor.setTimeout (->
          params = _.values(params)
          params.push(cb)
          i18n.get.apply this, params
          Meteor.clearInterval ticker
        ), 250
      )(arguments)
      return _l10n["#{locale}.#{param}"] or ''

  ###
  @function
  @name renderString
  @description Render string - replace Handlebars placeholders by values
  
  @param {string}  property        - Name of property in _l10n object
  @param {mix}     replacements    - Object, array, or string of replacements
  @param {string}  postfix         - Unique postfix, appended to property string
  
  @BUG: Dos not returns values on Live-updates without timeout, but if you go by routes
  @TODO: Debug bug
  ###
  renderString = (property, replacements, postfix) ->
    for key of i18n.config
      if _.isObject i18n.config[key]
        rendered = _l10n["#{i18n.config[key].code}.#{property}"]
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
          _l10n["#{i18n.config[key].code}.#{property}#{postfix}"] = rendered

  
  ###
  @description Run i18n.init() function
               with default path to i18n/ folder
  ###
  i18n.init i18n.path
  


###
# CLIENT SIDE
###
if Meteor.isClient
  _Strings = {}
  ###
  @description i18n helper UI Spacebars helper
  @example {{i18n 'string'}}
  ###
  Template.registerHelper "i18n", () ->
    i18n.get.apply(this, arguments)
  
  ###
  @namespace i18n
  @property {string} userLocale - User's browser locale
            Detect user's browser locale
  ###
  i18n.userLocale = (if (Meteor.isClient) then window.navigator.userLanguage or window.navigator.language or navigator.userLanguage else i18n.defaultLocale)
  
  ###
  @function
  @name loadLocalizations
  @description Load localization files into _Localizations property
  @param {string} locale - Two letter locale code
  ###
  loadLocalizations = (locale) ->
    _Localizations = i18n.internalizationCollection.findOne(type: "localizations").value
    reactivateObject _Localizations
    _Localizations[locale] if locale

  
  ###
  @function
  @name reactivateObject
  @description Check if properties of multidimensional object is reactive,
               if it is not - define reactive property on it
  @param {object} object - Object we're working on
  @param {parent} string - Parent object property
  ###
  reactivateObject = (object, parent) ->
    unless object.isReactive
      for key of object
        if key isnt "isReactive"
          if Object::toString.call(object[key]) is "[object Object]"
            reactivateObject object[key], (if (parent) then "#{parent}.#{key}" else key)
          else
            defineReactiveProperyWrapper _l10n, "#{parent}.#{key}", object[key]

  
  ###
  @function
  @name defineReactiveProperyWrapper
  @description Wrapper for quick Object.defineReactiveProperty() function.
  @param {object}  obj      - Object we're working on
  @param {string}  key      - Property name
  @param {mix}     value    - New property's value
  ###
  defineReactiveProperyWrapper = (obj, key, value) ->
    if !_.has obj, key
      Object.defineReactiveProperty obj, key, value, ((property, value, object) ->
        _Strings[property] = value if !_.has _Strings, property
      ), ((property) ->
        return _Strings[property] if _.has _Strings, property
      ), (property, value) ->
        _Strings[property] = value

  
  ###
  @function
  @name loadConfig
  @description Load configuration object into i18n.config property
  ###
  loadConfig = ->
    i18n.config = i18n.internalizationCollection.findOne(type: "config").value
    i18n.config

  
  ###
  @function
  @namespace i18n
  @property {function} setLocale - Set locale (by ISO code)
  @description Set new locale if it is configured in /private/i18n/i18n.json config file.
               Update session's and localStorage or cookie (via Meteor.storage) dependencies
  @param {string} locale - Two letter locale code
  ###
  i18n.setLocale = (locale) ->
    if i18n.isStarted
      if _Localizations[locale]
        i18n.currentLocale = locale
        Meteor.storage.set "locale", locale
        Session.set "i18nCurrentLocale", locale
        i18nConfigArray = []
        for key of _Localizations
          i18nConfigArray.push
            name: key
            value: i18n.config[key]
            currentLocale: Session.get "i18nCurrentLocale"
        Session.set "i18nConfig", i18nConfigArray
      else if _Localizations[i18n.config.defaultLocale]
        i18n.setLocale i18n.config.defaultLocale
      else
        throwError 404, locale
    else
      i18n.init locale

    i18n.currentLocale

  
  ###
  @function
  @namespace i18n
  @property {function} init - Set default locale (by ISO code)
  @description Set default locale and initialize internalization service
  @param {string} defaultLocale - Two letter locale code
  ###
  i18n.init = (defaultLocale) ->
    if i18n.isReady and not i18n.isStarted
      userLocale = i18n.userLocale.split("-")[0]
      loadConfig()
      loadLocalizations()

      if defaultLocale and i18n.config[defaultLocale]
        i18n.defaultLocale = defaultLocale
      else if i18n.config.defaultLocale
        i18n.defaultLocale = i18n.config.defaultLocale
      else
        throwError 404, defaultLocale

      Meteor.storage.set "locale", (if (Meteor.storage.get("locale")) then Meteor.storage.get("locale") else (if (i18n.config[userLocale]) then userLocale else i18n.defaultLocale))
      i18n.isStarted = true
      i18n.setLocale Meteor.storage.get("locale")
    else unless i18n.isReady
      Meteor.setTimeout (->
        i18n.init defaultLocale
      ), 250

  
  ###
  @function
  @name throwError
  @description Trow templated errors
  
  @param {string|int}  code    - Error code, similar to http codes
  @param {string}      string  - Additional string to be inserted into error messages
  ###
  throwError = (code, string) ->
    switch code
      when 404
        text = "No locale \"#{string}\" is definded in /private/i18n/i18n.json config file"
        description = "Check /private/i18n/i18n.json file for \"#{string}\" locale."
      else
        text = "Something is goes wrong in /packages/ostrio:i18n/ostrio:i18n.js"
        description = "Please check /packages/ostrio:i18n/ostrio:i18n.js for errors"
    throw new Meteor.Error([ code ], text, description)

  
  ###
  @function
  @namespace i18n
  @property {function}  get          - Get values, and do pattern replaces from current localization
  @param    {string}    locale       - [OPTIONAL] Two-letter localization code
  @param    {string}    param        - string in form of dot notation, like: folder1.folder2.file.key.key.key... etc.
  @param    {mix}       replacements - Object, array, or string of replacements
  ###
  i18n.get = () ->
    if arguments[0] and arguments[0].indexOf('.') isnt -1
      locale = Session.get "i18nCurrentLocale"
      param = arguments[0]
      xStart = 1
    else
      locale = arguments[0]
      param = arguments[1]
      xStart = 2

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
          replacements = arguments[x].hash if !_.isEmpty(arguments[x].hash)
        else
          replacements.push arguments[x]
        x++
        
    if !_.has _Strings, "#{locale}.#{param}"
      return if i18n.onWrongKey.returnKey then param else ""

    else if replacements and Object.getOwnPropertyNames(replacements).length > 0
      postfix = SHA256 param + JSON.stringify replacements
      if !_.has _Strings, "#{locale}.#{param}#{postfix}"
        renderString param, replacements, postfix
      return _Strings["#{locale}.#{param}#{postfix}"]

    else
      return (if (_.has _Strings, "#{locale}.#{param}") then _Strings["#{locale}.#{param}"] else (if (param.indexOf(".") isnt -1) then "" else param))

  
  ###
  @function
  @name renderString
  @description Render string - replace Handlebars placeholders by values
  
  @param {string}  property        - Name of property in _l10n object
  @param {mix}     replacements    - Object, array, or string of replacements
  @param {string}  postfix         - Unique postfix, appended to property string
  
  @BUG: Does not returns values on Live-updates without timeout, but if you go by routes
  @TODO: Debug bug
  ###
  renderString = (property, replacements, postfix) ->
    for key of i18n.config
      if _.isObject i18n.config[key]
        rendered = _l10n["#{i18n.config[key].code}.#{property}"]
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
          defineReactiveProperyWrapper _l10n, "#{i18n.config[key].code}.#{property}#{postfix}", rendered

  
  ###
  @description Subscribe to i18n collection, call i18n.init on connection callback
  ###
  Meteor.subscribe "i18n", ->
    i18n.isReady = true
    i18n.init @defaultLocale unless i18n.isStarted


i18n.locale = ->
  if Meteor.isServer then @currentLocale else Session.get 'i18nCurrentLocale'

###
@function
@name renderReplace
@description Smart Handlebars placeholders replacing

@param {string}  string          - Name of property in _l10n object
@param {mix}     replacements    - Object, array, or string of replacements
@param {array}   matches         - Array of all found Handlebars placeholders
@param {int}     index           - Current index from matches array
###
renderReplace = (string, replacements, matches, index) ->
  escapedMatch = matches[index].replace("{{", "").replace("}}", "").trim()
  unless replacements[escapedMatch]
    if _.isArray replacements
      string.replace matches[index], if replacements[index] then replacements[index] else ''
    else if escapedMatch.indexOf(".") isnt -1
      params = escapedMatch.split "."
      if replacements[params[0]] and _.isObject replacements
        i = 0
        while i < params.length
          replacement = replacements[params[i]]
          i++
        string.replace matches[index], if replacement then replacement else ''
    else
      string.replace matches[index], ''

  else if matches[index] and replacements[escapedMatch]
    string.replace matches[index], replacements[escapedMatch]