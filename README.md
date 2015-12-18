# SoraTel

## What is this?

Soracom SIM controller by telephone.

## Quick start

* Create [Twilio](https://www.twilio.com/) account.
  * get new phone number to control soracom SIMs.
  * Get Twilio auth token.
* Create [Heroku](https://www.heroku.com/) account.
* Press Deploy button and configure.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/tmtysk/soratel)

* Visit [Twilio dashboard](https://www.twilio.com/user/account/voice/phone-numbers) and set Request URL to `GET https://<yourappname>.herokuapp.com/twilio` on incoming voice call.
* Now, try to call to the number gotten on Twilio!
