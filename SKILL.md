---
name: openclaw-html-slides
description: 使用 HTML/CSS/JS 制作演示文稿（幻灯片）。触发场景：(1) 用户说"做 PPT"、"生成幻灯片"、"做个演示文稿" (2) 用户提供了文档链接（官网/文档）要求制作科普 PPT (3) 用户要求基于某个主题制作 HTML 幻灯片。核心能力：抓取网页内容 → 生成 PPT（必须先出 3 个风格预览让用户选 → 确认后才生成完整版）。遵循 references/responsive-guide.md 中的 CSS/JS 规范，防止窄屏溢出。
---

# openclaw-html-slides

用 HTML/CSS/JS 制作可浏览器播放的演示文稿。

## 工作流程（必须遵守）

```
用户需求 → 确认受众/页数/内容重点/风格
         ↓
    生成 3 个风格预览（A/B/C）
         ↓
   用户选择（或修改后确认）
         ↓
   生成完整 HTML + PDF
         ↓
   浏览器打开验收
```

**禁止**：不出预览就直接生成完整版。

---

## Step 1：收集需求（不超过 3 轮提问）

| 问题 | 选项 |
|------|------|
| 受众 | A=技术背景 / B=一般用户 / C=非技术人员 |
| 页数 | 短版 5-8 / 完整版 10-15 / 详细版 15-20 |
| 内容重点 | A=功能演示 / B=架构原理 / C=使用场景 |
| 风格 | A=Neon Cyber / B=Minimal Clean / C=Dark Professional |

---

## Step 2：生成 3 个预览

每个预览是**封面 + 1页内容**，独立 HTML 文件，路径：
`workspace/slides/[project-name]/preview-[A|B|C].html`

预览文件要包含：
- 风格 Logo 展示
- 3 个核心特性卡片
- 标签词展示

**预览生成后立刻用 `Invoke-Item` 打开让用户直观选择。**

---

## Step 3：用户确认后生成完整版

完整文件路径：`workspace/slides/[project-name]/index.html`

**必须遵循 `references/responsive-guide.md` 的 CSS/JS 规范（见下方摘要）。**

生成完毕后：
1. 用 Playwright 截图 1280×720 / 1920×1080 / 1440×900 全部页面验证
2. 用 `Invoke-Item` 打开 HTML 验收
3. 可选：运行 `scripts/export-pdf.mjs` 导出 PDF

---

## 响应式设计规范（必读）

> ⚠️ 核心教训：窄屏（1280px）下 `min-width:100vw` 会导致每页只有 1280px，内容溢出。必须用 JS scale 方案。

### 正确方案摘要（完整版见 `references/responsive-guide.md`）

**HTML 结构**：
```html
<body>
  <div style="position:fixed;inset:0;overflow:hidden;z-index:1" id="viewport">
    <div class="slides-container" id="slides">
      <div class="slide" id="slide-1">...</div>
      <div class="slide" id="slide-N">...</div>
    </div>
  </div>
  <div class="nav">◀ <div id="dots"></div> ▶</div>
</body>
```

**CSS**：
```css
body { overflow: hidden; margin: 0; }
.slides-container {
  display: flex;
  width: calc(1920px * N);  /* N = 页数 */
  position: absolute; top: 0; left: 0;
}
.slide {
  min-width: 1920px; width: 1920px; height: 100vh;
  /* 不要用 min-width: 100vw */
}
.nav { position: fixed; z-index: 200; }
/* 导航点必须横向 */
#dots { display: flex; flex-direction: row; gap: 10px; }
```

**JS（scale + 导航）**：
```javascript
const SLIDE_W = 1920, SLIDE_H = 1080;
const slidesEl = document.getElementById('slides');

function getScale() {
  return Math.min(window.innerWidth / SLIDE_W, window.innerHeight / SLIDE_H);
}
function applyTransform() {
  const scale = getScale();
  const scaledW = SLIDE_W * scale;
  const cx = (window.innerWidth - scaledW) / 2;
  const cy = (window.innerHeight - SLIDE_H * scale) / 2;
  slidesEl.style.transform = 'scale(' + scale + ')';
  slidesEl.style.left = cx + 'px';
  slidesEl.style.top = cy + 'px';
  slidesEl.style.transformOrigin = 'top left';
}
function goTo(idx) {
  const scale = getScale();
  const scaledW = SLIDE_W * scale;
  const cx = (window.innerWidth - scaledW) / 2;
  slidesEl.style.left = (cx - idx * scaledW) + 'px';
  updateDots();
}
window.goTo = goTo;
window.applyTransform = applyTransform;
window.addEventListener('resize', () => applyTransform());
updateDots(); applyTransform();
```

### 常见错误

| 错误写法 | 问题 |
|---------|------|
| `min-width: 100vw` | 1280px 视口下每页只有 1280px |
| `width: 100vw` | 同上，内容按 1920px 设计会溢出 |
| `overflow-x: auto` | 子元素 overflow 会截断导航 |

---

## 样式参考

详见 `references/design-patterns.md`：
- **Neon Cyber**：深黑 + 霓虹青/紫发光 + 网格纹理
- **Minimal Clean**：浅灰白 + 蓝绿扁平卡片
- **Dark Professional**：深蓝黑 + 紫蓝→薄荷绿渐变

通用组件：卡片网格、导航栏、代码块、架构流程图、时间线、对比表格。

---

## 脚本

- `scripts/export-pdf.mjs`：导出 PDF（Playwright 截图 + PDF 组装）
- `scripts/screenshot-slides.js`：多分辨率截图验证

## 文件结构

```
openclaw-html-slides/
├── SKILL.md
├── references/
│   ├── responsive-guide.md   ← 响应式规范（必读）
│   └── design-patterns.md    ← 样式参考
└── scripts/
    ├── export-pdf.mjs
    └── screenshot-slides.js
```
