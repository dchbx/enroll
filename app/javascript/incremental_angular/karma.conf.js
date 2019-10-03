// Karma configuration file, see link for more information
// https://karma-runner.github.io/1.0/config/configuration-file.html

module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage-istanbul-reporter'),
      require('@angular-devkit/build-angular/plugins/karma'),
      require('karma-junit-reporter')
    ],
    client: {
      clearContext: false // leave Jasmine Spec Runner output visible in browser
    },
    coverageIstanbulReporter: {
      dir: require('path').join(__dirname, '../../../angular_coverage'),
      reports: ['html', 'lcovonly', 'text-summary', 'json', 'json-summary'],
      fixWebpackSourcePaths: true,
      skipFilesWithNoCoverage: true
    },
    reporters: ['progress', 'kjhtml', 'junit', 'coverage-istanbul'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['ChromeHeadless'],
    singleRun: true,
    restartOnFileChange: true,
    junitReporter: {
      outputDir: require('path').join(__dirname, '../../../tmp'),
      outputFile: "incremental_angular_TEST.xml",
      useBrowserName: false,
      suite: 'incremental_angular'
    }
  });
};
