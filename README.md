# Firefly Horizon 主题

Firefly Horizon 是 Firefly 论坛使用的 Discourse 独立主题。这个目录可以直接作为 GitHub 主题仓库根目录使用，仓库根目录必须直接包含 `about.json`。

## 仓库结构

```text
about.json                         主题元数据，Discourse 远程安装必须读取这个文件
settings.yml                       主题设置
common/                            通用 SCSS 入口
desktop/                           桌面端 SCSS 入口
scss/                              主题样式模块
javascripts/discourse/             主题前端组件和初始化代码
locales/                           主题多语言文案
screenshots/                       主题截图
.github/workflows/validate.yml     GitHub 校验流程
```

不要把整个 `firefly-bbs` 项目作为主题仓库推到 GitHub。Discourse 从 GitHub 安装主题时，只会在仓库根目录查找 `about.json`。

## 当前改造范围

- 顶部 header：增加“文档 / 社区”入口，固定显示语言切换器和全局搜索入口，并优化注册、登录、搜索入口的视觉。
- 首页欢迎区：使用主题 locale 输出标题、副标题和搜索区样式。
- 话题列表：高上下文话题卡改为接近设计稿的行式布局，保留 Discourse 原生动态数据。
- 左侧 sidebar：调整间距、选中态和 hover 态。
- 色板：新增 Firefly / Firefly Dark 色板，同时保留 Horizon 原有色板。

## GitHub 开发

如果这是第一次把主题独立推到 GitHub，在主题目录执行：

```bash
cd /mnt/x/www/firefly/firefly-bbs/discourse/themes/firefly-horizon

git init
git branch -M main
git add .
git commit -m "初始化 Firefly Horizon 主题"
git remote add origin git@github.com:<组织或用户名>/firefly-horizon.git
git push -u origin main
```

如果 GitHub 仓库已经存在，只需要设置远程地址：

```bash
cd /mnt/x/www/firefly/firefly-bbs/discourse/themes/firefly-horizon

git remote add origin git@github.com:<组织或用户名>/firefly-horizon.git
git push -u origin main
```

日常开发流程：

```bash
cd /mnt/x/www/firefly/firefly-bbs/discourse/themes/firefly-horizon

git status
git add .
git commit -m "描述本次主题修改"
git push
```

## 本地 Discourse 同步

开发环境运行后，在项目根目录执行：

```bash
cd /mnt/x/www/firefly/firefly-bbs
./deploy/dev/sync-firefly-horizon-theme.sh
```

脚本会把容器内的 `/src/themes/firefly-horizon` 作为主题源码导入到本地 Discourse 数据库，并把 `Firefly-Horizon` 设为默认主题。

注意：Discourse 主题最终生效的是数据库里的主题记录，不是源码目录里的文件本身。源码改动后需要重新执行同步脚本，页面才会加载最新主题。

## 从 GitHub 安装

在目标 Discourse 后台安装：

```text
管理后台 -> 外观 -> 主题 -> 安装 -> 从 Git 仓库安装
```

公开仓库使用 HTTPS 地址：

```text
https://github.com/<组织或用户名>/firefly-horizon.git
```

私有仓库使用 SSH 地址，并在 Discourse 后台配置对应私钥：

```text
git@github.com:<组织或用户名>/firefly-horizon.git
```

安装后需要确认：

```text
主题名称：Firefly-Horizon
默认浅色色板：Firefly
默认暗色色板：Firefly Dark
```

如果需要页脚显示浅色 / 深色 / 自动切换按钮，后台站点设置里需要保持：

```text
interface_color_selector = sidebar_footer
```

同时当前主题必须配置暗色色板，否则 Discourse 官方 `interface_color_selector` 不会渲染。

## 远程更新

主题代码推送到 GitHub 后，在目标 Discourse 后台进入该主题，点击检查更新并更新即可。

也可以在目标容器中通过 Discourse 任务安装或更新远程主题，具体以目标站点的部署方式为准。

## 后台上传主题 zip

如果目标站点不能直接访问 GitHub，可以在 `firefly-bbs` 项目根目录打包：

```bash
cd /mnt/x/www/firefly/firefly-bbs
./deploy/dev/package-firefly-horizon-theme.sh ./firefly-horizon-importable.zip
```

正确的后台上传包必须在 zip 根目录直接包含 `about.json`，结构类似：

```text
about.json
common/
desktop/
javascripts/
locales/
scss/
settings.yml
```

检查命令：

```bash
unzip -Z1 firefly-horizon-importable.zip | grep '^about.json$'
```

后台上传路径：

```text
管理后台 -> 外观 -> 主题 -> 导入
```

## 主题 bundle 包

下面这个命令导出的不是后台上传包，也不是 GitHub 远程安装包：

```bash
docker exec discourse_dev bash -lc 'cd /src && runuser -u discourse -- /bin/bash -lc "bin/rake \"themes:export_theme_bundle[Firefly-Horizon,/tmp/firefly-horizon-bundle.zip]\""'
```

它导出的是 Discourse 的主题 bundle，包含主题、组件和当前站点里的主题设置覆盖。这个包的结构类似：

```text
manifest.json
theme/about.json
components/
```

这种包只能在目标 Discourse 里用配套任务导入：

```bash
docker cp firefly-horizon-bundle.zip <目标容器名>:/tmp/firefly-horizon-bundle.zip

docker exec <目标容器名> bash -lc 'cd /src && runuser -u discourse -- /bin/bash -lc "bin/rake \"themes:import_theme_bundle[/tmp/firefly-horizon-bundle.zip]\""'
```

不要把 bundle 包拿到后台主题上传页面导入，后台会因为 zip 根目录没有 `about.json` 而报错。

## 选择建议

本地边开发边看效果时，使用 `sync-firefly-horizon-theme.sh`。

正式站点能访问 GitHub 时，优先使用 GitHub 远程安装。

目标站点不能访问 GitHub 时，使用 `package-firefly-horizon-theme.sh` 生成后台上传包。

需要迁移“已经在后台调过的主题设置、组件挂载关系”时，才使用 `themes:export_theme_bundle` 和 `themes:import_theme_bundle`。
