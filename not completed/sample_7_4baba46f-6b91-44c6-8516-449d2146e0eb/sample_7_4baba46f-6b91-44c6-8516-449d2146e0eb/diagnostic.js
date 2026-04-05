const puppeteer = require('puppeteer');

(async () => {
    let browser;
    try {
        browser = await puppeteer.launch({
            executablePath: '/snap/bin/chromium',
            headless: 'new',
            args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu', '--disable-dev-shm-usage']
        });
        const page = await browser.newPage();
        await page.goto('http://localhost:8080/index.html', { waitUntil: 'networkidle0' });
        const html = await page.evaluate(() => document.querySelector('.header').outerHTML);
        console.log(html);
    } catch (e) {
        console.error(e);
    } finally {
        if (browser) await browser.close();
    }
})();
