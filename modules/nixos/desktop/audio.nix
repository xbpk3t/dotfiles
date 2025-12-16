{pkgs, ...}: {
  # PipeWire 音频栈（含 Pulse/JACK 兼容）+ rtkit
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # 实时调度，提升低延迟音频体验
  security.rtkit.enable = true;

  # 保留 pulseaudio 客户端兼容，但禁用原生 daemon 以避免冲突
  services.pulseaudio.enable = false;

  # 提供 `pactl` 等工具
  environment.systemPackages = with pkgs; [
    pulseaudio
  ];
}
