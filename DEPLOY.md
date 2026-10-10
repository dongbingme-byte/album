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

### 3. 图片的两个来源方案

- **方案一（当前默认）**：图片直接提交进 `exampleSite/content/`，构建自包含、不依赖外网。
  注意：主题自带的 `exampleSite/pull-images.sh` 原从 Unsplash 下载示例照片，现已失效，已停用。
- **方案二（推荐长期）**：图片放 Cloudflare R2 桶，CI 构建前自动同步进 `content/`，
  仓库不再存图片。见「四、Cloudflare R2 图床」。

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

## 四、Cloudflare R2 图床（原图云端管理）

把原图放 Cloudflare R2 桶，GitHub Actions 构建前用 `scripts/sync-images.sh` 把整桶
同步到 `exampleSite/content/`。照片就不再提交进 git 仓库，可集中管理、多站复用；
主题的缩略图/懒加载处理完全不变。

### 1. 创建桶并上传照片

1. Cloudflare 控制台 → R2 → Create bucket，如 `album-photos`
2. 桶内目录结构必须**镜像 `exampleSite/content/`**，文件名与相册 `index.md` 里
   `resources[].src` 完全一致，否则相册没图。例如：

   ```
   album-photos/
   └── animals/
       ├── (animals 封面图).jpg         ← content/animals/_index.md 引用
       └── cats/
           ├── 图1.jpg                  ← content/animals/cats/index.md 引用
           └── 图2.jpg
   ```

3. 本机安装 rclone 后上传（rclone 直接吃 R2 的 S3 兼容接口，无需配置文件）：
   ```bash
   RCLONE_CONFIG_R2_TYPE=s3 RCLONE_CONFIG_R2_PROVIDER=Cloudflare \
   RCLONE_CONFIG_R2_ACCESS_KEY_ID=<key> RCLONE_CONFIG_R2_SECRET_ACCESS_KEY=<secret> \
   RCLONE_CONFIG_R2_ENDPOINT=https://<AccountID>.r2.cloudflarestorage.com \
   rclone copy ./要上传的目录 r2:album-photos/ --create-empty-src-dirs
   ```

### 2. 创建 R2 API 令牌（只读即可）

Cloudflare 控制台 → R2 → **Manage R2 API Tokens** → Create API Token
- 权限**只勾目标桶的 Object Read**（CI 只需拉图）
- 记下 **Access Key ID** 和 **Secret Access Key**（Secret 只在创建时显示一次，先复制好）

### 3. 把四个值配成 GitHub Actions Secrets

| Secret | 值 |
| --- | --- |
| `R2_ENDPOINT` | `https://<AccountID>.r2.cloudflarestorage.com`（`<AccountID>` 在 R2 概览页右上角） |
| `R2_BUCKET` | 你的桶名，如 `album-photos` |
| `R2_ACCESS_KEY_ID` | 上一步的 Access Key ID |
| `R2_SECRET_ACCESS_KEY` | 上一步的 Secret Access Key |

仓库 **Settings → Secrets and variables → Actions** → New repository secret 逐一添加；
或把四个值给 Claude 用 `gh secret set` 存入（密钥只进 Secrets，不会写进仓库文件/工作流）。

### 4. CI 行为

- `hugo.yml` 构建前运行 `./scripts/sync-images.sh`：**检测到四个 secret 就同步桶**；
  **没配 secret 则跳过**，继续用仓库内已有图片，因此配置前后站点都不会断。
- 配好 secret 且桶里有图后，任何 push 都会自动拉图并重新部署。

### 5. 迁移：配好 R2 后可移除仓库里的旧图

确认桶里图片齐全、站点正常后再做。只移除图片文件的 git 跟踪（本地文件保留，
图片也仍在 git 历史里可找回）：
```bash
git rm --cached $(find exampleSite/content -name '*.jpg')
git commit -m "Move photos to Cloudflare R2"
git push origin main
```

## 五、日常问题排查

| 现象 | 处理 |
| --- | --- |
| 提交后站点没更新 | 打开仓库 Actions 页看构建是否失败，点进失败步骤看日志 |
| 相册没有图 | 确认照片文件名与 `index.md` 的 `resources[].src` 完全一致 |
| 配了 R2 但仍没图 | 核对四个 secret 名称无误；确认桶内目录/文件名与 `resources` 一致；看 Actions 里 "Sync images from Cloudflare R2" 步骤日志 |
| 想回到「图片随仓库走」 | 删除四个 secret（或移除 workflow 里的 Sync 步骤），把图片重新提交进仓库 |
| 想用私有仓库部署 | 免费套餐不支持，需改用付费套餐或换平台（Vercel/Cloudflare 等） |