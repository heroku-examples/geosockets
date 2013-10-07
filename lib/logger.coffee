# Custom Logger only produces console output if browser
# supports it and a `debug` query param is present

module.exports = ->
  if window['console'] and location.search.match(/debug/)
    console.log.apply(console,arguments)