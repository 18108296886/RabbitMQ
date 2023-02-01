const { By, Key, until, Builder } = require('selenium-webdriver')
require('chromedriver')
const assert = require('assert')
const { buildDriver, goToHome, captureScreensFor, teardown, delay } = require('../utils')

const LoginPage = require('../pageobjects/LoginPage')
const OverviewPage = require('../pageobjects/OverviewPage')
const AdminTab = require('../pageobjects/AdminTab')
const LimitsAdminTab = require('../pageobjects/LimitsAdminTab')

<<<<<<< HEAD
describe('user_limits', function () {
=======
describe('List all user_limits', function () {
>>>>>>> 5ad72497a3 (Test display limits when there are none)
  let login
  let overview
  let captureScreen

  before(async function () {
    driver = buildDriver()
    await goToHome(driver)
    login = new LoginPage(driver)
    overview = new OverviewPage(driver)
    adminTab = new AdminTab(driver)
    limitsSection = new LimitsAdminTab(driver)
    captureScreen = captureScreensFor(driver, __filename)

    await login.login('guest', 'guest')
    if (!await overview.isLoaded()) {
      throw new Error('Failed to login')
    }

  })

  it('when there are no limits', async function () {
    await overview.clickOnAdminTab()
    await adminTab.clickOnLimits()
<<<<<<< HEAD
    assert.equal(0, (await limitsSection.list_user_limits()).length)
=======

    await limitsSection.list_user_limits()

>>>>>>> 5ad72497a3 (Test display limits when there are none)
  })


  after(async function () {
    await teardown(driver, this, captureScreen)
  })
})
