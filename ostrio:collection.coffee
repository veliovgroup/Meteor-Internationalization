Meteor.startup ->
  i18nInternalizationCollection = new Meteor.Collection "internalization"

if Meteor.isServer
  Meteor.publish "i18n", ->
    i18nInternalizationCollection.find
      type:
        $in: [
          "localizations"
          "config"
        ]
    ,
      fields:
        value: 1
        type: 1

Meteor.subscribe "i18n"  if Meteor.isClient