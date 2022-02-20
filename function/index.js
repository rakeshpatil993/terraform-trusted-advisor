const utilities = require('./utilities.js')

exports.handler = async (event, context) => {
  // Get Trusted Advisor checks
  const checks = await utilities.describeTrustedAdvisorChecks()
  const results = { success: [], errors: [] }

  // Loop through the checks and return their result, whether they succeed or not
  await Promise.all(checks.map(async check => {
    if (!utilities.unrefreshableChecks.includes(check.id) && !utilities.removedChecks.includes(check.id)) {
      console.log(`[info] Refreshing ${check.name} (ID: ${check.id})`)

      // Refresh each check individually (there's no batch API endpoint)
      await utilities.refreshTrustedAdvisorCheck(check.id).then(result => {
        console.log(`[success] Refreshed ${check.name} (ID: ${check.id}) successfully`)
        results.success.push(result)
      }).catch(error => {
        console.log(`[error] Cannot refresh ${check.name} (ID: ${check.id})`)
        results.errors.push(error)
      })
    }
  }))

  // Print out some errors if there are any
  if (results.errors.length) {
    console.log('[error] For errors, please see below:')
    results.errors.forEach(error => {
      console.log(error)
    })
  }

  // Output our finished statement
  console.log(`[finished] ${results.success.length}/${results.success.length + results.errors.length} refreshed.`)
}