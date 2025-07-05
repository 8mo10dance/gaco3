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
This project uses Docker Compose to manage two separate services:
- `app`: Runs `node index.js` to fetch data from the YouTube API.
- `formatter`: Runs `format.sh` to process the output from the `app` service.

First, ensure you have a `.env` file in the project root with your API key:

```
YOUTUBE_API_KEY=YOUR_API_KEY
```

To run the `app` service and pipe its output to the `formatter` service:

```bash
docker-compose run --rm app | docker-compose run --rm -T formatter
```

This command will:
1. Run the `app` service (defined by `Dockerfile.app`).
2. Pipe its standard output to the standard input of the `formatter` service.
3. Run the `formatter` service (defined by `Dockerfile.formatter`).
4. Remove both containers after execution (`--rm`).

## Dependencies

- `@anaisbetts/mcp-youtube`
- `@kirbah/mcp-youtube`
- `googleapis`
