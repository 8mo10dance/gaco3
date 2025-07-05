# mcp-youtube-server

## Description

This is a server application that interacts with the YouTube Data API.

## Installation

To install the dependencies, navigate to the project directory and run:

```bash
npm install
```

## Usage

First, build the Docker image:

```bash
docker compose build
```

Ensure you have a `.env` file in the project root with your API key:

```
YOUTUBE_API_KEY=YOUR_API_KEY
```

Then, you can build and run the service using Docker Compose:

```bash
docker-compose up
```

To run the service and pipe its output to `format.sh` (this will run the `app` service once and remove the container):

```bash
docker-compose run --rm app node index.js | ./format.sh
```

## Dependencies

- `@anaisbetts/mcp-youtube`
- `@kirbah/mcp-youtube`
- `googleapis`
