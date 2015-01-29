Meteor.startup ->
  @i18n = {} if !@i18n
  i18n.internalizationCollection = new Meteor.Collection "internalization" if !i18n.internalizationCollection

if Meteor.isServer
  Meteor.publish "i18n", ->
    i18n.internalizationCollection.find
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