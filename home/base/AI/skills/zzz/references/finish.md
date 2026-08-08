---
name: finish
role: composite
pipeline:
  - uu
  - conclusion
description: session的统一收尾操作
---



依次逐条执行以下命令，注意需要顺序执行，且在前一条执行完成后再发送后一条

```shell
/zzz uu
/zzz conclusion
!ccx session export
/exit
```
