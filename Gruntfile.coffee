module.exports = (grunt) ->

  grunt.initConfig

    # compass:
    #   public:
    #     options:
    #       sassDir: 'src/styles'
    #       cssDir: 'public/styles'
    #       outputStyle: 'compact'
    #       relativeAssets: true
    #       colorOutput: false

    coffeeify:
      basic:
        src: ['client.coffee']
        dest: "public/client.js"

    watch:
      coffeeify:
        files: ['client.coffee']
        tasks: ['coffeeify']
      # sass:
      #   files: ['src/styles/*.sass']
      #   tasks: ['compass']

  grunt.loadNpmTasks 'grunt-coffeeify'
  # grunt.loadNpmTasks 'grunt-contrib-compass'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'default', ['coffeeify']