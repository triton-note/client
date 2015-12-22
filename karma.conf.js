module.exports = function(config) {
  config.set({
    basePath: 'dart',

    frameworks: ['dart-unittest'],

    files: [
      'test/**/*_test.dart',
      {pattern: 'lib/**/*.dart', watched: true, included: false, served: true}
    ],

    reporters: ['progress', 'junit'],
    
    junitReporter: {
      outputFile: 'test/results.xml',
      suite: ''
    },

    logLevel: config.LOG_DEBUG,

    autoWatch: true,

    plugins: [
      'karma-dart',
      'karma-junit-reporter',
      'karma-chrome-launcher'
    ],
    
    browsers: ['Dartium']
  });
};
