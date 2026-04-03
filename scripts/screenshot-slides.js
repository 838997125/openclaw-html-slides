// screenshot-slides.js - 截图验证幻灯片
// 用法: node screenshot-slides.js <html路径> [输出目录]
// 示例: node screenshot-slides.js ../my-ppt/index.html ../my-ppt/screenshots
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const htmlFile = process.argv[2];
const outputDir = process.argv[3] || path.dirname(htmlFile) + '/screenshots';

if (!htmlFile) {
  console.error('用法: node screenshot-slides.js <html路径> [输出目录]');
  process.exit(1);
}

const htmlAbs = path.resolve(htmlFile);
const slidesDir = path.dirname(htmlAbs);
fs.mkdirSync(outputDir, { recursive: true });

const CHROME = 'C:\\Users\\HUAWEI\\AppData\\Local\\ms-playwright\\chromium-1208\\chrome-win64\\chrome.exe';

async function main() {
  const browser = await chromium.launch({ executablePath: CHROME });
  const errors = [];

  // 截图 3 种分辨率
  for (const [label, vp] of [['1280x720', [1280, 720]], ['1920x1080', [1920, 1080]], ['1440x900', [1440, 900]]]) {
    const page = await browser.newPage();
    page.on('pageerror', e => errors.push(label + ' error: ' + e.message));
    await page.setViewportSize({ width: vp[0], height: vp[1] });
    await page.goto('file://' + htmlAbs, { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(2000);

    // 等待 goTo 函数可用
    try {
      await page.waitForFunction(() => typeof window.goTo === 'function', { timeout: 5000 });
    } catch {
      console.log('goTo not found, using scroll');
    }

    // 获取总页数
    const total = await page.evaluate(() => {
      return window.total || document.querySelectorAll('.slide').length;
    }).catch(() => 12);

    console.log('分辨率', label, '- 总页数:', total);

    for (let i = 0; i < total; i++) {
      await page.evaluate((idx) => {
        if (typeof window.goTo === 'function') window.goTo(idx);
        else window.scrollTo({ top: 0, left: idx * 1920, behavior: 'instant' });
      }, i).catch(() => {});
      await page.waitForTimeout(500);
      const safeLabel = label.replace(/[^\d]/g, '');
      await page.screenshot({
        path: path.join(outputDir, safeLabel + '-s' + String(i + 1).padStart(2, '0') + '.png'),
        fullPage: false
      });
    }
    await page.close();
  }

  if (errors.length) console.log('Errors:', errors);
  else console.log('截图完成，无错误');
  await browser.close();
}

main().catch(e => { console.error(e); process.exit(1); });
