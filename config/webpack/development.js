process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const environment = require('./environment');

var webpack_environment = environment.toWebpackConfig()

webpack_environment.module.rules.push(
	{ test: /\.ts$/,
		loaders: ['awesome-typescript-loader?configFileName=./app/javascript/incremental_angular/tsconfig.app.json', 'angular2-template-loader'],
		exclude: [/\.(spec|e2e)\.ts$/, /\.spec\.ts$/, /node_modules\/(?!(ng2-.+))/, /\.e2e-spec\.ts$/] }
);

webpack_environment.module.rules.push(
	{
		test: /\.html$/,
		loader: 'html-loader'
	}
);

webpack_environment.entry.incremental_angular = "./app/javascript/incremental_angular/main.ts";

module.exports = webpack_environment;
