# 响应式幻灯片设计规范

> ⚠️ 来自真实 Bug 教训：1280px 窄屏下 `min-width:100vw` 导致内容严重溢出。
> 遵守以下规范，避免重现。

---

## 核心原则

**所有尺寸基于 1920×1080 设计稿，用 JS scale 适配任意分辨率。**

---

## ❌ 禁止使用的模式

### 1. `min-width: 100vw`（绝对禁止）

```css
/* 错误：1280px 视口下，100vw=1280px，但每页内容按 1920px 设计 */
.slide { min-width: 100vw; } /* ← 灾难 */

/* 错误原因：
   视口 1280px 时，.slide { min-width: 100vw } = 1280px
   但 .slide 内所有内容（padding/文字/卡片）按 1920px 排版
   结果：内容被截断，溢出不可见 */
```

### 2. `overflow-x: auto / scroll`（不要依赖浏览器滚动）

```css
/* 错误：overflow 会截断子元素，导航和内容都被 clip */
.slides-container { overflow-x: auto; }
```

### 3. 混合 `width: 960px` + `overflow: hidden`（脆弱）

```css
/* 脆弱：内容稍宽就溢出视口 */
.content { width: 960px; overflow: hidden; }
```

---

## ✅ 正确模式：CSS Fixed-Width + JS Scale

### HTML 结构

```html
<body>
  <!-- 固定视口层，禁止滚动 -->
  <div style="position:fixed;inset:0;overflow:hidden;z-index:1" id="viewport">
    <div class="slides-container" id="slides">
      <!-- 每一页固定 1920px 宽 -->
      <div class="slide" id="slide-1">...</div>
      <div class="slide" id="slide-2">...</div>
    </div>
  </div>

  <!-- 导航栏放 viewport 外，z-index:200 浮在上面 -->
  <div class="nav">
    <button onclick="prevSlide()">◀</button>
    <div id="dots"></div>
    <button onclick="nextSlide()">▶</button>
  </div>
</body>
```

### CSS

```css
body { overflow: hidden; margin: 0; }

.slides-container {
  display: flex;
  /* 关键：固定 1920px * N，用 JS 控制 left 定位 */
  width: calc(1920px * N);  /* N = 页数 */
  height: 100vh;
  position: absolute;
  top: 0;
  left: 0;
}

.slide {
  /* 关键：固定 1920px，不用 100vw */
  min-width: 1920px;
  width: 1920px;
  height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 60px 80px;
}

/* 导航栏 */
.nav {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 200;
  background: rgba(0,0,0,0.6);
  padding: 10px 20px;
  border-radius: 30px;
  border: 1px solid var(--border);
  backdrop-filter: blur(10px);
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 12px;
}

/* 导航点必须横向 */
#dots {
  display: flex;
  flex-direction: row;
  gap: 10px;
  align-items: center;
}
.nav-dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: rgba(255,255,255,0.2);
  cursor: pointer;
  transition: all 0.3s;
}
.nav-dot.active {
  background: var(--cyan);
  box-shadow: var(--glow-cyan);
  transform: scale(1.4);
}
```

### JavaScript

```javascript
const total = N;       // 页数
const SLIDE_W = 1920;
const SLIDE_H = 1080;
const slidesEl = document.getElementById('slides');

function getScale() {
  return Math.min(window.innerWidth / SLIDE_W, window.innerHeight / SLIDE_H);
}

function applyTransform() {
  const scale = getScale();
  const scaledW = SLIDE_W * scale;
  const scaledH = SLIDE_H * scale;
  const cx = (window.innerWidth - scaledW) / 2;
  const cy = (window.innerHeight - scaledH) / 2;
  slidesEl.style.transform = 'scale(' + scale + ')';
  slidesEl.style.left = cx + 'px';
  slidesEl.style.top = cy + 'px';
  slidesEl.style.transformOrigin = 'top left';
}

let current = 0;

function goTo(idx) {
  if (idx < 0 || idx >= total) return;
  current = idx;
  const scale = getScale();
  const scaledW = SLIDE_W * scale;
  const cx = (window.innerWidth - scaledW) / 2;
  slidesEl.style.left = (cx - idx * scaledW) + 'px';
  updateDots();
}

function updateDots() {
  const dots = document.getElementById('dots');
  if (!dots) return;
  dots.innerHTML = '';
  for (let i = 0; i < total; i++) {
    const d = document.createElement('div');
    d.className = 'nav-dot' + (i === current ? ' active' : '');
    d.onclick = () => goTo(i);
    dots.appendChild(d);
  }
}

function nextSlide() { goTo((current + 1) % total); }
function prevSlide() { goTo((current - 1 + total) % total); }

// 键盘导航
document.addEventListener('keydown', e => {
  if (e.key === 'ArrowRight' || e.key === 'ArrowDown' || e.key === ' ') { e.preventDefault(); nextSlide(); }
  else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') { e.preventDefault(); prevSlide(); }
});

// 触屏滑动
let touchStartX = 0;
document.addEventListener('touchstart', e => { touchStartX = e.touches[0].clientX; });
document.addEventListener('touchend', e => {
  const dx = e.changedTouches[0].clientX - touchStartX;
  if (Math.abs(dx) > 50) { dx > 0 ? prevSlide() : nextSlide(); }
});

// 导出给截图脚本用
window.goTo = goTo;
window.applyTransform = applyTransform;

window.addEventListener('resize', () => applyTransform());
updateDots();
applyTransform();
```

---

## 边距与间距规则

基于 1920×1080 设计稿：
- **左右 padding**：`80px`（标题页）/ `60px 80px`（内容页）
- **内容区 max-width**：`900-960px`
- **底部留**：`80px`（给导航栏，内容不能贴底）
- **字体大小**：用 `clamp()` 避免小屏过小
  ```css
  .title { font-size: clamp(28px, 4vw, 56px); }
  .card { padding: 28px 24px; font-size: 13px; }
  ```
- **卡片网格**：`gap: 20px`，用 `max-width` 约束，不用固定 px 宽度

---

## 调试方法

在 Playwright 中用 1280×720 截图所有页面：

```javascript
const overflows = Array.from(document.querySelectorAll('*')).filter(el => {
  const r = el.getBoundingClientRect();
  return r.right > window.innerWidth + 2 || r.left < -2;
});
console.log('溢出元素:', overflows.length);
```

**必须验证的分辨率**：1920×1080（设计稿）、1280×720（常见笔记本）、1440×900（Mac）。
