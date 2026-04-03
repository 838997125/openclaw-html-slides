# 设计风格参考

## 风格 A：Neon Cyber（科技感）

**关键词**：深黑背景、霓虹发光、网格纹理、赛博朋克

```css
/* === 变量 === */
:root {
  --bg: #0a0a0f;
  --cyan: #00f5ff;
  --purple: #bf5fff;
  --green: #39ff14;
  --pink: #ff2d78;
  --glass: rgba(255,255,255,0.04);
  --border: rgba(0,245,255,0.2);
  --glow-cyan: 0 0 20px rgba(0,245,255,0.6), 0 0 60px rgba(0,245,255,0.2);
  --glow-purple: 0 0 20px rgba(191,95,255,0.6), 0 0 60px rgba(191,95,255,0.2);
  --glow-green: 0 0 20px rgba(57,255,20,0.6), 0 0 60px rgba(57,255,20,0.2);
}

/* === 背景网格纹理 === */
body { background: var(--bg); }
body::before {
  content: '';
  position: fixed; inset: 0;
  background-image:
    linear-gradient(rgba(0,245,255,0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0,245,255,0.03) 1px, transparent 1px);
  background-size: 60px 60px;
  pointer-events: none;
  z-index: 0;
}

/* === 霓虹发光字 === */
.glow-cyan { color: var(--cyan); text-shadow: var(--glow-cyan); }
.glow-purple { color: var(--purple); text-shadow: var(--glow-purple); }
.glow-green { color: var(--green); text-shadow: var(--glow-green); }

/* === 标签胶囊 === */
.tag {
  padding: 8px 20px; border-radius: 20px;
  font-size: 13px; font-weight: 700; letter-spacing: 1px;
  border: 1px solid;
}
.tag-c { border-color: var(--cyan); color: var(--cyan); background: rgba(0,245,255,0.06); }
.tag-p { border-color: var(--purple); color: var(--purple); background: rgba(191,95,255,0.06); }
.tag-g { border-color: var(--green); color: var(--green); background: rgba(57,255,20,0.06); }
```

## 风格 B：Minimal Clean（简约专业）

**关键词**：浅色背景、蓝绿点缀、大量留白、扁平卡片

```css
:root {
  --bg: #fafafa;
  --blue: #2563eb;
  --green: #059669;
  --red: #dc2626;
}
body { background: var(--bg); }
.card {
  background: #fff; border: 1px solid #e5e7eb;
  border-radius: 12px; padding: 24px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}
.tag { padding: 6px 16px; border-radius: 14px; font-size: 12px; font-weight: 700; }
.tag-b { background: rgba(37,99,235,0.06); border: 1px solid rgba(37,99,235,0.25); color: #2563eb; }
.tag-g { background: rgba(5,150,105,0.06); border: 1px solid rgba(5,150,105,0.25); color: #059669; }
```

## 风格 C：Dark Professional（深色专业）

**关键词**：深蓝黑背景、紫蓝→薄荷绿渐变、磨砂毛玻璃

```css
:root {
  --bg: #0f1117;
  --indigo: #818cf8;
  --emerald: #34d399;
  --border: rgba(99,102,241,0.3);
}
body { background: var(--bg); }
body::before {
  content: '';
  position: fixed; inset: 0;
  background:
    radial-gradient(ellipse at 20% 50%, rgba(99,102,241,0.08) 0%, transparent 60%),
    radial-gradient(ellipse at 80% 20%, rgba(16,185,129,0.06) 0%, transparent 50%);
  pointer-events: none;
}
.logo {
  background: linear-gradient(135deg, var(--indigo), var(--emerald));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
.card {
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 14px; backdrop-filter: blur(4px);
}
```

---

## 通用组件样式

### 卡片网格

```css
.cards { display: grid; gap: 20px; }
.cards-2 { grid-template-columns: 1fr 1fr; }
.cards-3 { grid-template-columns: 1fr 1fr 1fr; }
.cards-4 { grid-template-columns: 1fr 1fr; max-width: 800px; }

.card {
  background: var(--glass);
  border: 1px solid var(--border);
  border-radius: 12px; padding: 28px 24px;
  transition: border-color 0.3s, transform 0.3s;
}
.card:hover { border-color: var(--cyan); transform: translateY(-4px); }
.card-icon { font-size: 32px; margin-bottom: 12px; }
.card-title { font-size: 16px; font-weight: 700; margin-bottom: 8px; color: var(--cyan); }
.card-desc { font-size: 13px; color: rgba(255,255,255,0.55); line-height: 1.6; }
```

### 代码块

```css
.code-block {
  background: rgba(0,0,0,0.5);
  border: 1px solid rgba(0,245,255,0.15);
  border-radius: 10px; padding: 24px 32px;
  font-family: 'Courier New', monospace; font-size: 14px;
  color: #e0e0e0; line-height: 1.8;
  width: 100%; max-width: 700px;
}
.cm { color: rgba(255,255,255,0.3); }   /* 注释 */
.nb { color: var(--cyan); }             /* 数字/命令 */
.kw { color: var(--purple); }           /* 关键字 */
.str { color: var(--green); }            /* 字符串 */
```

### 架构流程图

```css
.arch-flow { display: flex; align-items: center; flex-wrap: wrap; justify-content: center; gap: 8px; }
.arch-box { padding: 16px 24px; border-radius: 10px; text-align: center; min-width: 140px; border: 1px solid; }
.arch-box-main { border-color: var(--cyan); color: var(--cyan); background: rgba(0,245,255,0.06); }
.arch-box-sub  { border-color: var(--purple); color: var(--purple); background: rgba(191,95,255,0.06); }
.arch-box-leaf { border-color: var(--green); color: var(--green); background: rgba(57,255,20,0.06); }
.arch-arrow { color: rgba(255,255,255,0.3); font-size: 24px; padding: 0 8px; }
```

### 时间线

```css
.timeline { display: flex; gap: 0; align-items: flex-start; width: 100%; }
.timeline-item { flex: 1; text-align: center; position: relative; padding: 0 16px; }
.timeline-item::after {
  content: ''; position: absolute; top: 20px; right: 0;
  width: 100%; height: 2px;
  background: linear-gradient(90deg, var(--cyan), var(--purple));
}
.timeline-item:last-child::after { display: none; }
.timeline-dot {
  width: 16px; height: 16px; border-radius: 50%;
  background: var(--cyan); margin: 12px auto 16px; position: relative; z-index: 1;
  box-shadow: var(--glow-cyan);
}
.timeline-title { font-size: 13px; font-weight: 700; color: var(--cyan); margin-bottom: 6px; }
.timeline-desc { font-size: 12px; color: rgba(255,255,255,0.5); line-height: 1.5; }
```

### 对比表格

```css
.compare-table { width: 100%; max-width: 800px; border-collapse: collapse; font-size: 14px; }
.compare-table th {
  padding: 14px 20px; text-align: left; color: var(--cyan);
  border-bottom: 1px solid var(--border);
  font-family: 'Orbitron', monospace; font-size: 12px; letter-spacing: 2px;
}
.compare-table td {
  padding: 12px 20px; color: rgba(255,255,255,0.7);
  border-bottom: 1px solid rgba(255,255,255,0.04);
}
.compare-table tr:last-child td { border-bottom: none; }
.check { color: var(--green); }
.cross { color: var(--pink); }
```

### 场景卡片

```css
.scenario-card {
  background: var(--glass); border: 1px solid var(--border);
  border-radius: 16px; padding: 32px; width: 100%; max-width: 520px;
  text-align: center;
}
.scenario-card .emoji { font-size: 48px; margin-bottom: 16px; }
.scenario-card h3 { color: var(--cyan); font-size: 20px; margin-bottom: 12px; }
.scenario-card p { color: rgba(255,255,255,0.6); font-size: 14px; line-height: 1.7; }

/* 2列网格布局（推荐用于场景页） */
.scene-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; width: 100%; max-width: 900px; }
```

### 引用块

```css
.quote {
  font-size: clamp(18px, 2.5vw, 28px); font-style: italic;
  color: rgba(255,255,255,0.7);
  border-left: 3px solid var(--cyan);
  padding-left: 28px; max-width: 800px; line-height: 1.6;
}
```
