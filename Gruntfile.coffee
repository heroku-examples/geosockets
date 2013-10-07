module.exports = (grunt) ->
  grunt.initConfig

    coffeeify:
      basic:
        src: ['client.coffee', 'lib/not-npm-ish/*.js']
        dest: "public/client.js"

    watch:
      coffeeify:
        files: ['client.coffee', 'lib/*.coffee']
        tasks: ['coffeeify']

  grunt.loadNpmTasks 'grunt-coffeeify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'default', ['coffeeify']