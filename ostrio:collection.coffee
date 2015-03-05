Meteor.startup ->
  @i18n ?= {}
  i18n.internalizationCollection ?= new Meteor.Collection "internalization"

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

  Meteor.subscribe "i18n" if Meteor.isClient