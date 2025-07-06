
#!/bin/bash
jq -r '.[] | "Title: \(.snippet.title)\nURL: https://www.youtube.com/watch?v=\(.id.videoId)\nPublished At: \(.snippet.publishedAt)\n---"'
