## 高频操作

- `CMD + E` # 用来 toggle切换最近编辑文件，体验极佳！！！（把“切换仅更改的文件”快捷键勾掉）
- `CMD + shift + Y` [Local history] Show History For Selection
- `CMD + shift + P` [Git] Show History For Selection



### Tool Window

- `CMD + shift + T` Terminal Tool
- `CMD + shift + N` Structure Tool


### 切换tab

- `CMD + shift + ]/[` 切换window # macos本身的shortcut
- `Option +shift + ]/[` 切换Terminal的tab # Main Menu -> Window -> Editor Tabs -> Select Next/Previous Tab

---

- ***`CMD + shift + '`*** 调整Tool Window Size(在当前size和max size之间toggle调整，非常实用)
- `Ctrl + shift + O` 在Terminal打开该文件 # 非常好用，也是中高频操作（用于想要在terminal里操作当前文件）。比如说修改文件名，常规操作是双击当前文件，找到“在Terminal中打开”，然后再修改，这就需要两步。又或者在当前项目的文件树里，那就是 select Open File，然后shift+f6修改文件名。总之都不如直接在命令行操作方便。





## Toolbar

- `Ctrl + Option + 上下方位键` # 调整活动工具窗口大小（比如 Terminal）
- `CMD + esc` # 隐藏当前活动栏（默认是 fn+esc，改键）


## git

- `CMD + K` git 提交栏
- `CMD + shift + K` # git 推送

## scratch

- `CMD + Ctrl + N` 创建新scratch文件
- `CMD + Ctrl + T` 查看当前scratch列表 # 添加快捷键


（比之前用 vscode 作为临时编辑器强 1w 倍，支持跨项目使用、调试、语法高亮、文件历史记录等正常项目文件里的所有功能）

## Run

- ***`Ctrl + R`*** # run
- ***`Ctrl + D`*** # debug

## 单文件

- `CMD+F` 单文件查找
- `CMD+R` 单文件替换

- `CMD+x` 删除当前行
- `CMD+d` 复制当前行
- `Fn + 上/下` 页面顶部/底部
- `CMD + 左/右` 行首/行尾
- `CMD + L` 跳转行号

- `CMD + -/+` # 收起/展开代码块
- `CMD + shift+r` # 全局替换
- `CMD + fn + 左/右` 文件头/文件尾

- `CMD + Option + L` # 当前页面 Reformat Code

- `CMD + fn + F12` # 按文件结构导航 (used to search and track functions directly)



## 字符串操作

- `CMD + Shift + U` # uppercase

## golang 相关

- `Option + enter` # 选择“生成构造函数"
- 选中 struct 中该成员，Option+Enter，选择“生成 getter/setter” # 生成 struct 中某个成员的 getter/setter
- 鼠标点击到某个变量后，shift+f6 # 批量修改变量名


### goland 快捷操作 struct

- 把 json 直接复制到 goland 即可 # json直接转换成结构体

- `ctrl+T+引入类型` # 即可把结构体的内嵌结构体，转移到外部
- `Option+enter+Change field name style in tags` # 即可修改命名风格，为小驼峰
- `Option+enter+Update key value in tags` # 给所有 tag 添加omitempty等标签
- `Option+enter+Add key to tags` # 给所有 tag 添加 key
