{ ... }:

{
  programs.jq = {
    enable = true;

    # 自定义颜色配置
    colors = {
      # null 值颜色
      null = "0;37";      # 白色
      # false 值颜色
      false = "0;37";     # 白色
      # true 值颜色
      true = "0;37";      # 白色
      # 数字颜色
      numbers = "0;37";   # 白色
      # 字符串颜色
      strings = "0;32";   # 绿色
      # 数组颜色
      arrays = "1;37";    # 亮白色
      # 对象颜色
      objects = "1;37";   # 亮白色
      # 对象键颜色
      objectKeys = "1;34"; # 亮蓝色
    };
  };

  # 添加有用的 jq 别名到 shell
  programs.bash.shellAliases = {
    # 格式化 JSON
#    jqp = "jq '.'";
#    # 紧凑输出
#    jqc = "jq -c";
#    # 按键排序
#    jqs = "jq -S";
#    # 原始输出（不带引号）
#    jqr = "jq -r";
  };
}
