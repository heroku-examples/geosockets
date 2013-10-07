module.exports = (grunt) ->
  grunt.initConfig

    casper:
      test:
        options:
          test: true
        files:
          'test/casper-results.xml': ['test/clientTest.coffee']

    coffeeify:
      basic:
        src: ['client.coffee', 'lib/vendor/*.js']
        dest: "public/client.js"

    watch:
      casper:
        files: ['public/client.js', 'test/clientTest.coffee'],
        tasks: ['casper']
      coffeeify:
        files: ['client.coffee', 'lib/*.coffee']
        tasks: ['coffeeify']

  grunt.loadNpmTasks 'grunt-casper'
  grunt.loadNpmTasks 'grunt-coffeeify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'default', ['casper', 'coffeeify']