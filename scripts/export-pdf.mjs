// export-pdf.mjs — Export HTML slides to PDF using Playwright
// 用法: node export-pdf.mjs <html目录> <html文件名> <输出PDF> [截图目录] [宽] [高]
// 示例: node export-pdf.mjs . index.html out.pdf screenshots 1920 1080
import { chromium } from 'playwright';
import { createServer } from 'http';
import { readFileSync, mkdirSync, unlinkSync, writeFileSync } from 'fs';
import { join, extname } from 'path';

const SERVE_DIR     = process.argv[2] || '.';
const HTML_FILE     = process.argv[3] || 'index.html';
const OUTPUT_PDF    = process.argv[4] || 'slides.pdf';
const SCREENSHOT_DIR = process.argv[5] || 'screenshots';
const VP_WIDTH  = parseInt(process.argv[6]) || 1920;
const VP_HEIGHT = parseInt(process.argv[7]) || 1080;

const MIME_TYPES = {
  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.svg': 'image/svg+xml',
  '.webp': 'image/webp', '.woff': 'font/woff', '.woff2': 'font/woff2', '.ttf': 'font/ttf',
};

const server = createServer((req, res) => {
  const decodedUrl = decodeURIComponent(req.url);
  let filePath = join(SERVE_DIR, decodedUrl === '/' ? HTML_FILE : decodedUrl);
  try {
    const content = readFileSync(filePath);
    const ext = extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
    res.end(content);
  } catch {
    res.writeHead(404);
    res.end('Not found: ' + decodedUrl);
  }
});

const port = await new Promise(r => server.listen(0, () => r(server.address().port)));
console.log('  Server on port', port);

const CHROME = 'C:\\Users\\HUAWEI\\AppData\\Local\\ms-playwright\\chromium-1208\\chrome-win64\\chrome.exe';
const browser = await chromium.launch({ executablePath: CHROME });
const page = await browser.newPage({ viewport: { width: VP_WIDTH, height: VP_HEIGHT } });

await page.goto('http://localhost:' + port + '/', { waitUntil: 'networkidle' });
await page.evaluate(() => document.fonts.ready);
await page.waitForTimeout(2000);

const slideCount = await page.evaluate(() => document.querySelectorAll('.slide').length);
console.log('  Found', slideCount, 'slides at', VP_WIDTH + 'x' + VP_HEIGHT);

if (slideCount === 0) {
  console.error('  ERROR: No .slide elements found.');
  await browser.close();
  server.close();
  process.exit(1);
}

mkdirSync(SCREENSHOT_DIR, { recursive: true });
const screenshotPaths = [];

// Try goTo first (JS-scale slides), fall back to scroll
const hasGoTo = await page.evaluate(() => typeof window.goTo === 'function');
console.log('  Navigation method:', hasGoTo ? 'goTo()' : 'scroll');

for (let i = 0; i < slideCount; i++) {
  if (hasGoTo) {
    await page.evaluate((idx) => window.goTo(idx), i);
  } else {
    // Fallback: scroll to slide position
    const positions = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('.slide')).map(s => {
        const r = s.getBoundingClientRect();
        return r.left + document.documentElement.scrollLeft;
      });
    });
    await page.evaluate((pos) => window.scrollTo({ top: 0, left: pos, behavior: 'instant' }), positions[i]);
  }

  await page.waitForTimeout(600);

  const shotPath = join(SCREENSHOT_DIR, 'slide-' + String(i + 1).padStart(3, '0') + '.png');
  await page.screenshot({ path: shotPath, fullPage: false, animations: 'disabled' });
  screenshotPaths.push(shotPath);
  console.log('  Captured slide ' + (i + 1) + '/' + slideCount);
}

await browser.close();
server.close();

// Assemble PDF
console.log('  Assembling PDF...');
const browser2 = await chromium.launch({ executablePath: CHROME });
const pdfPage = await browser2.newPage();

const imagesHtml = screenshotPaths.map(p => {
  const data = readFileSync(p).toString('base64');
  return '<div class="page"><img src="data:image/png;base64,' + data + '" /></div>';
}).join('\n');

const pdfHtml = '<!DOCTYPE html><html><head><style>' +
  '*{margin:0;padding:0}' +
  '@page{size:' + VP_WIDTH + 'px ' + VP_HEIGHT + 'px;margin:0}' +
  '.page{width:' + VP_WIDTH + 'px;height:' + VP_HEIGHT + 'px;page-break-after:always;overflow:hidden}' +
  '.page:last-child{page-break-after:auto}' +
  'img{width:' + VP_WIDTH + 'px;height:' + VP_HEIGHT + 'px;display:block;object-fit:contain}' +
  '</style></head><body>' + imagesHtml + '</body></html>';

await pdfPage.setContent(pdfHtml, { waitUntil: 'load' });
await pdfPage.pdf({
  path: OUTPUT_PDF,
  width: VP_WIDTH + 'px',
  height: VP_HEIGHT + 'px',
  printBackground: true,
  margin: { top: 0, right: 0, bottom: 0, left: 0 },
});

await browser2.close();
screenshotPaths.forEach(p => unlinkSync(p));
console.log('  PDF saved to:', OUTPUT_PDF);
