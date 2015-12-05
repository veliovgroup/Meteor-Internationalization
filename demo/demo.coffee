@i18n = new I18N()

demoObj =
  first: "Value 1"
  second: "Value 2"
  third: "Value 3"

if Meteor.isClient
  Template.demo.helpers
    demoObj:           -> demoObj
    currentLocale:     -> i18n.currentLocale.get()
    samplePlaceholder: -> 'Sample-Placeholder'

  Template.demo.events
    'click .switch-language': (e, template) ->
      e.preventDefault()
      if e.currentTarget.dataset?.code
        i18n.setLocale e.currentTarget.dataset.code
      false

Meteor.startup ->
  test = ->
    console.info i18n.get 'main.text.one'
    console.info i18n.get 'main.text.two', 'Sample-Placeholder'
    console.info i18n.get 'main.text.three', 'Sample-Placeholder'
    console.info i18n.get 'main.text.four', 'One', 'Two', 'Three'
    console.info "[Non default locale]", i18n.get 'ru', 'main.text.four', 'One', 'Two', 'Three'
    console.info "[Non default locale]", i18n.get 'ru', 'main.text.four', demoObj
    console.info "[Non-existent key + Non default locale]", i18n.get 'ru', 'main.non-existent-key'
    console.info "[Non-existent key]", i18n.get 'main.non-existent-key'
    console.info "[Non-existent key with replacements]", i18n.get 'main.non-existent-key', 'One', 'Two', 'Three'
    console.info i18n.get 'main.text.four', demoObj

  if Meteor.isServer
    test()
  else
    i18n.subscribeToAll -> test()