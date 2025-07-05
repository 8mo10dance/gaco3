# mcp-youtube-server

## Description

This is a server application that interacts with the YouTube Data API.

## Installation

To install the dependencies, navigate to the project directory and run:

```bash
npm install
```

## Usage

To start the server, run:

```bash
node index.js
```

To run the server and format the output using `format.sh`:

```bash
YOUTUBE_API_KEY=YOUR_API_KEY node index.js | ./format.sh
```

Replace `YOUR_API_KEY` with your actual YouTube Data API key.

## Dependencies

- `@anaisbetts/mcp-youtube`
- `@kirbah/mcp-youtube`
- `googleapis`
