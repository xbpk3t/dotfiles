args @ {mylib, ...}:
(mylib.mkManagedComposeModule {
  name = "rsshub";
  composeFile = ../rsshub/compose.yml;
  description = "RSSHub stack managed via nix-managed-docker-compose";
  ingressLabel = "RSSHub";
  secretEnvDefault = {
    YOUTUBE_KEY = "youtubeApiKey";
    YUQUE_TOKEN = "yuqueToken";
    GITHUB_ACCESS_TOKEN = "githubAccessToken";
    PIXIV_REFRESHTOKEN = "pixivRefreshToken";
    SPOTIFY_CLIENT_ID = "spotifyClientId";
    SPOTIFY_CLIENT_SECRET = "spotifyClientSecret";
  };
})
args
