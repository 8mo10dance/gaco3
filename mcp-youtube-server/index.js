const { google } = require('googleapis');

const youtube = google.youtube({
  version: 'v3',
  auth: process.env.YOUTUBE_API_KEY,
});

async function main() {
  const res = await youtube.search.list({
    part: 'snippet',
    channelId: 'UC1nqXaKzG4hd1SRFVra16gw',
    eventType: 'completed',
    type: 'video',
    order: 'date',
    maxResults: 5,
  });
  console.log(JSON.stringify(res.data.items));
}

main();
