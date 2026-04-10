---
title: 备份工具review
isOriginal: true
---


***同步和备份是两码事，同步和同步也是两码事***

restic和kopia都有hm，但是要注意在darwin上都不可用（支持systemd，不支持launchd（会静默失败））

告警，kopia本身内置 notification，用restic则需要自己处理






```yaml
        - date: 2025-07-02
          des: 移除了【restic】。“Kopia 在备份效率、恢复灵活性和场景覆盖上相较restic已形成代差优势”。具体来说，1、【备份效率】kopia相比restic的效率高30%，因为restic只在check阶段并发执行，在migrate阶段是单线程的（查看restic的issues/5339）。2、【恢复灵活性】图形化操作（Kopia-UI）、部分恢复（文件级粒度）、挂载快照为虚拟磁盘。而restic只支持cli，并且恢复需全量下载快照。3、【场景覆盖】企业级特性：策略化管理、存储分层（热/冷数据）、K8s 集成（Velero 默认引擎）。相较之下restic只有基础的备份功能。4、【轻量化】但是restic在轻量化上是有优势的，可以理解为kopia也是有daemon的，只不过大部分时候都是sleep状态，到了cronTime的时候才执行（查看snapshot/policy/scheduling_policy.go里的代码，注意并非用robfig/cron实现，而是用timewheel实现的）。而restic则不同，是没有daemon的，完全是个cli工具，也就说其crontask是基于OS本身的cron实现的。所以更轻量。
        - date: 2025-07-31
          des: 移除了【seafile】，之前以为这个是网盘，实际上seafile更类似【坚果云】，二者的核心功能都是实时同步文件修改，也都支持作为webdav挂载之类的附加功能。换句话说，相较于网盘，seafile跟kopia更类似，但是二者有何不同？又为啥移除掉seafile呢？二者的区别归根到底其核心在于seafile要求写权限，所以相对应的就可以自动解冲突。而kopia则指要求读权限，毫无疑问更安全，但是遇到冲突就需要自己手动解决。除此之外，seafile会记录文件修改记录，所以如果有合规要求可以选择。而kopia则相对更轻量、更省资源（cron执行）。
        - date: 2025-08-12
          des: “上一轮”的胜者【kopia】也要被移除掉了。今天需要用来代替之前docs-images的repo，发现rclone本身就有sync，跟kopia对比了一下，发现rclone就能满足我的需求了。kopia相较于rclone的feats在于可以创建多版本快照（比如每天备份），可以直接回滚到某天的文件。基于此，对于冲突也有更好的解决方案，kopia的 增量备份+全局去重机制 可避免多人协作时的文件冲突。比如说，用户A修改文件A，用户B同时修改文件B → Kopia 会生成两个独立快照，保留双方更改。而rclone sync 会以最新同步端覆盖全部文件，可能导致一方修改丢失。所以***简单来说还是分场景，如果是协作场景，那就用kopia（因为确实会有冲突的问题）。如果是个人使用，rclone内置的sync也够用了。***

```



```yaml
    - url: https://github.com/mutagen-io/mutagen
      zk: 文件双向同步
      record:
        - date: 2026-01-30
          des: 移除【syncthing（一个基于P2P实现的“远程同步文件”工具，提供GUI和CLI（通过web操作）两种下载方式，用homebrew安装，默认CLI。用这个就可以代替之前用的【坚果云】了 (Some time ago used Nutstore to sync code bidirectionally. I've also used other cloud service like icloud, dropbox, google-cloud to implement similar task.)。）】，太重了，没必要。

```


syncthing 不存在 server和client的分工，每个node都“既又”，***既可以像server一样坚挺port，接受别人连接，也会像client一样用来连接别人***。只不过我们本地机器作为node，在内网（所以会以为是client），而用来做同步的VPS机器，则在公网（以为是server）
