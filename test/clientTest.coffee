casper.start "http://localhost:5000/", ->

  @waitUntilVisible "#geosockets", ->
    @test.assertExists "#geosockets"
    @test.assertExists ".leaflet-container"
    # @test.assertEquals(typeof(@getGlobal('map')), 'object')

casper.run ->
  @test.done()
  @test.renderResults(true)