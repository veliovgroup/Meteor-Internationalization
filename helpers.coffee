###
@function
@name throwError
@description Trow templated errors

@param {string|int}  code    - Error code, similar to http codes
@param {String}      string  - Additional string to be inserted into error messages
###
@throwError = (code, string) ->
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
@name renderReplace
@description Smart Handlebars placeholders replacing

@param {String}  string          - Name of property in _l10n object
@param {mix}     replacements    - Object, array, or string of replacements
@param {array}   matches         - Array of all found Handlebars placeholders
@param {int}     index           - Current index from matches array
###
@renderReplace = (string, replacements, matches, index) ->
  escapedMatch = matches[index].replace("{{", "").replace("}}", "").trim()
  unless replacements[escapedMatch]
    switch
      when _.isArray replacements 
        string.replace matches[index], if replacements[index] then replacements[index] else ''
      when !!~escapedMatch.indexOf "."
        params = escapedMatch.split "."
        if replacements[params[0]] and _.isObject replacements
          i = 0
          while i < params.length
            replacement = replacements[params[i]]
            i++
          string.replace matches[index], if replacement then replacement else ''
      else string.replace matches[index], ''
  else if matches[index] and replacements[escapedMatch]
    string.replace matches[index], replacements[escapedMatch]

###
@function
@name reactivateObject
@description Check if properties of multidimensional object is reactive,
             if it is not - define reactive property on it
@param {Object} object - Object we're working on
@param {parent} string - Parent object property
###
@reactivateObject = (object, parent) ->
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
@param {Object}  obj      - Object we're working on
@param {String}  key      - Property name
@param {mix}     value    - New property's value
###
@defineReactiveProperyWrapper = (obj, key, value) ->
  if not _.has obj, key
    Object.defineReactiveProperty obj, key, value, ((property, value, object) ->
      _Strings[property] = value if not _.has _Strings, property
    ), ((property) ->
      return _Strings[property] if _.has _Strings, property
    ), (property, value) ->
      _Strings[property] = value

###
@function
@name removeTrailingSlash
@description Removes trailing Slash from string if its exists
@param {String} string - String
###
@removeTrailingSlash = (string) ->
  if string.substr(-1) is "/"
    string.substr 0, string.length - 1
  else
    string