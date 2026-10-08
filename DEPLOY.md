# 手动部署与更新操作说明

本仓库 = hugo-theme-gallery 主题 + `exampleSite` 示例相册站。部署在 GitHub Pages，
构建由 GitHub Actions 自动完成（CI 在云端构建，无需本机安装 Hugo）。

- 线上站点：https://dongbingme-byte.github.io/album/
- 部署工作流：`.github/workflows/hugo.yml`（push 到 `main` 时自动构建并部署）

## 一、首次设置（做一次即可）

### 1. 仓库必须公开

免费版 GitHub Pages **只支持公开仓库**。
Settings → General → Danger Zone → Change visibility → Public。

### 2. 开启 GitHub Pages

Settings → Pages → Build and deployment → Source 选 **「GitHub Actions」**。

### 3. 示例图片已提交进仓库，无需下载

注意：主题自带的 `exampleSite/pull-images.sh` 原从 Unsplash 下载示例照片，现已失效，
本仓库已改为把图片直接提交进 `exampleSite/content/`，构建流程不再下载。

## 二、相册站的日常更新

### 上传新照片

1. 找到想放入的相册目录，如 `exampleSite/content/animals/cats/`
2. Code 页 → Add file → **Upload files**，把照片拖进去 → Commit（会直接推到 main）
3. 编辑同一个目录下的 `index.md`，在 `resources:` 里加一行：

   ```yaml
   resources:
     - src: 你上传的文件名.jpg
       title: 照片说明（可选）
   ```

   没有 `resources` 条目的照片不会显示在相册里。

### 新建一个相册

在 `exampleSite/content/` 下新建一个目录，里面放 `index.md`（front matter 带
`title`、`resources`）+ 照片，参考现有相册结构。想让它出现在首页列表，给
`menus: "main"` 和按顺序的 `weight`。

### 修改站点标题/作者

编辑 `exampleSite/config/_default/hugo.toml`（`title`、`params.author`、
`params.socialIcons` 等）。

### 触发重新部署

任何 push 到 `main` 都会自动重新构建。也可以去 Actions 页手动点 **Run workflow**。

## 三、中英文切换

主题自带了界面文案翻译（`i18n/`，含 `zh.yaml`），但**没有内置语言切换按钮**。
当前站点是单一英文。要做中英双语，需要：

1. 在 `hugo.toml` 配置多语言，如：

   ```toml
   defaultContentLanguage = "zh"
   [languages.zh]
     languageCode = "zh-CN"
     languageName = "中文"
     contentDir = "content/zh"
   [languages.en]
     languageCode = "en"
     languageName = "English"
     contentDir = "content/en"
   ```

2. 把内容分别放到 `content/zh/` 与 `content/en/`（目录结构一致，各语言一份）。
3. 不同语言通过 URL 访问（如 `/album/zh/...` 与 `/album/en/...`），
   Hugo 会自动输出 `<link rel="alternate" hreflang>`；主题不自带按钮，
   如需页面上可见的切换按钮需要额外定制。

## 四、日常问题排查

| 现象 | 处理 |
| --- | --- |
| 提交后站点没更新 | 打开仓库 Actions 页看构建是否失败，点进失败步骤看日志 |
| 相册没有图 | 确认照片文件名与 `index.md` 的 `resources[].src` 完全一致 |
| 想用私有仓库部署 | 免费套餐不支持，需改用付费套餐或换平台（Vercel/Cloudflare 等） |