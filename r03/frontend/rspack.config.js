const path = require('path');
module.exports = {
  entry: path.resolve(__dirname, 'src/index.tsx'),
  output: {
    path: path.resolve(__dirname, '../backend/app/assets/javascripts'),
    filename: 'bundle.js',
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
