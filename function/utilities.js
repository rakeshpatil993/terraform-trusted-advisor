const AWS = require('aws-sdk')
const support = new AWS.Support({
  apiVersion: '2013-04-15',
  region: 'us-east-1' // AWS Support API is only accessible from the us-east-1 region
})

const utilities = {
  /*
    These checks are being removed on November 18, 2020
    See: https://docs.aws.amazon.com/awssupport/latest/user/trusted-advisor.html
  */
  removedChecks: [
    'fH7LL0l7J9', // EBS Active Volumes
    'TyfdMXG69d', // ENA Driver Version for EC2 Windows Instances
    'V77iOLlBqz', // EC2Config Service for EC2 Windows Instances
    'Wnwm9Il5bG', // PV Driver Version for EC2 Windows Instances
    'yHAGQJV9K5' // NVMe Driver Version for EC2 Windows Instances
  ],
  /*
    These checks aren't refreshable via the API.
    This isn't included in the AWS documentation,
    but it is mentioned in the Trusted Advisor console.
    These checks are automatically refreshed multiple times a day by AWS.
  */
  unrefreshableChecks: [
    '0t121N1Ty3', // AWS Direct Connect Connection Redundancy
    '4g3Nt5M1Th', // AWS Direct Connect Virtual Interface Redundancy
    '8M012Ph3U5', // AWS Direct Connect Location Redundancy
    'ePs02jT06w', // Amazon EBS Public Snapshots
    'rSs93HQwa1' // Amazon RDS Public Snapshots
  ],
  describeTrustedAdvisorChecks () {
    return support.describeTrustedAdvisorChecks({
      language: 'en'
    }).promise().then(data => data.checks).catch(error => {
      console.log('[error] Cannot run support.describeTrustedAdvisorChecks:', error)
      throw new Error(error)
    })
  },
  refreshTrustedAdvisorCheck (checkId) {
    return support.refreshTrustedAdvisorCheck({
      checkId: checkId
    }).promise()
  }
}

module.exports = utilities