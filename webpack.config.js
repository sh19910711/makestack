var path = require('path');

const APP_PATH = path.join(__dirname, 'frontend');

module.exports = {
  context: APP_PATH,
  entry: ['main'],
  output: { path: __dirname + '/public/js', publicPath: '/js/', filename: 'bundle.js' },
  resolve: {
    extensions: ['', '.js'],
    root: [APP_PATH],
    alias: {
      'vue': 'vue/dist/vue.min.js',
      'vue-router': 'vue-router/dist/vue-router.min.js',
    }
  },
  module: {
    loaders: [
      { test: /\.html$/, loader: 'html-loader'},
      { test: /\.js$/,   loader: 'babel', exclude: /node_modules/ },
      { test: /\.scss$/, loader: 'style!css!sass' }
    ],
    preLoaders: [
      { test: /\.js$/, loader: 'eslint', exclude: /node_modules/ }
    ]
  },
  babel: { presets: ['es2015'], plugins: ['transform-runtime'] },
  vue: { loaders: { sass: 'style!css!sass' } },
  watchOptions: { poll: 1000 },
  sassLoader: {
    includePaths: [path.resolve(APP_PATH,  'css')]
  }
};
