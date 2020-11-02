process.env.NODE_ENV = process.env.NODE_ENV || 'production';

const environment = require('./environment');
const webpack = require('webpack');
const path = require('path');

var webpack_environment = environment.toWebpackConfig();

webpack_environment.module.rules.push({
  test: /\.html$/,
  loader: 'html-loader',
});

webpack_environment.plugins.push(
  new webpack.ProvidePlugin({
    jQuery: 'jquery',
    $: 'jquery',
    jquery: 'jquery',
  })
);

module.exports = webpack_environment;

const merge = require('webpack-merge');
const sassLoader = environment.loaders.get('sass');
const cssLoader = environment.loaders.get('css');

sassLoader.use.map(function (loader) {
  if (loader.loader === 'css-loader') {
    loader.options = merge(loader.options, { sourceMap: false });
  }
});

cssLoader.use.map(function (loader) {
  if (loader.loader === 'css-loader') {
    loader.options = merge(loader.options, { sourceMap: false });
  }
});
