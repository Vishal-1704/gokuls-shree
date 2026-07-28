const { join } = require('path');

/**
 * @type {import("puppeteer").Configuration}
 */
module.exports = {
  // Store Puppeteer Chrome cache inside the project directory to avoid corrupted global cache on hosting providers.
  cacheDirectory: join(__dirname, '.cache', 'puppeteer'),
};
