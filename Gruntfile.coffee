module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    nodemon:
      dev:
        options:
          file: 'server.coffee'
          ignoredFiles: ['.gitignore', 'README.md', 'LICENSE.txt', 'node_modules/**', 'data/**', 'src/3rdparty/**']
          watchedExtensions: ['js', 'json', 'coffee','yml']
          delayTime: 1
          legacyWatch: true
          cwd: __dirname
      muddy:
        options:
          file: 'muddy.coffee'
          ignoredFiles: ['.gitignore', 'README.md', 'LICENSE.txt', 'node_modules/**', 'data/**', 'src/3rdparty/**']
          watchedExtensions: ['js', 'json', 'coffee','yml']
          delayTime: 5
          legacyWatch: true
          cwd: __dirname
    watch:
      scripts:
        files: ['**/*.coffee','**/*.js','**/*.yml','config/config.json']
        tasks: ['concurrent:target']
        options:
          spawn: false
    concurrent:
      target:
        tasks: ['watch', 'nodemon:dev', 'nodemon:muddy']
        options:
          logConcurrentOutput: true

  grunt.loadNpmTasks 'grunt-nodemon'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-concurrent'

  grunt.registerTask 'default', ['concurrent:target']
