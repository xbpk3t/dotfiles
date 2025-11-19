args @ {mylib, ...}:
(mylib.mkManagedComposeModule {
  name = "miniflux";
  composeFile = ../miniflux/compose.yml;
  description = "Miniflux stack managed via nix-managed-docker-compose";
  ingressLabel = "Miniflux";
})
args
