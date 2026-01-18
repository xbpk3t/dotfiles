# hosts


## roles

关于 hosts，最重要的就是区分清楚不同的roles

这里分为三种

- workstation (ws)
- homelab
- vps







## 要求

- hosts里的配置项不应该有任何 `lib.mkDefault`，以保证其中配置没有歧义。否则会很容易出现。
