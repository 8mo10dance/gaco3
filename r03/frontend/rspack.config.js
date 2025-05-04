const path = require('path');
module.exports = {
  entry: path.resolve(__dirname, 'src/index.tsx'),
  output: {
    path: path.resolve(__dirname, 'public', 'packs'),
    filename: 'bundle.js',
    publicPath: '/packs/'
  },
  module: {
    rules: [
      { test: /\.css$/, use: ['style-loader', 'css-loader'] },
      { test: /\.(png|jpg|gif)$/, type: 'asset/resource' },
      { test: /\.(js|ts|tsx)$/, use: 'babel-loader' }
    ]
  },
  resolve: { extensions: ['.js', '.ts', '.tsx'] }
};
