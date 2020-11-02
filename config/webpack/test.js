process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const environment = require('./environment');

var webpack_environment = environment.toWebpackConfig();

webpack_environment.module.rules.push({
  test: /\.html$/,
  loader: 'html-loader',
});

module.exports = webpack_environment;
