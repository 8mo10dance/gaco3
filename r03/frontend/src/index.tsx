import React from 'react';
import { createRoot } from 'react-dom/client';

const App = () => <h1>Hello from React!</h1>;

document.addEventListener('DOMContentLoaded', () => {
  const rootEl = document.getElementById('root');
  if (rootEl !== null) {
    const root = createRoot(rootEl);
    root.render(<App />);
  }
})
