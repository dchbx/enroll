process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const environment = require('./environment');

environment.plugins.append(
  'UglifyJs',
  new UglifyJsPlugin({
    parallel: true,
    cache: true,
    sourceMap: true,
    uglifyOptions: {
      ie8: false,
      ecma: 5,
      warnings: false,
      mangle: {
        safari10: true,
      },
      compress: {
        warnings: false,
        comparisons: false,
      },
      output: {
        ascii_only: true,
      },
    },
  })
);

var webpack_environment = environment.toWebpackConfig();

webpack_environment.module.rules.push({
  test: /\.html$/,
  loader: 'html-loader',
});

module.exports = webpack_environment;
