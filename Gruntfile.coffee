module.exports = (grunt) ->
  grunt.initConfig

    coffeeify:
      basic:
        src: ['client.coffee']
        dest: "public/client.js"

    watch:
      coffeeify:
        files: ['client.coffee', 'lib/*.coffee']
        tasks: ['coffeeify']

  grunt.loadNpmTasks 'grunt-coffeeify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'default', ['coffeeify']