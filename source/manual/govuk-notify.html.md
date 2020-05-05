---
owner_slack: "#govuk-developers"
title: How we use GOV.UK Notify
section: Emails
type: learn
layout: manual_layout
parent: "/manual.html"
last_reviewed_on: 2020-04-29
review_in: 6 months
---

[GOV.UK Notify][notify] is a Government-as-a-Platform service that allows
clients of their API to send emails, text messages and letters. We use GOV.UK
Notify to send emails to users - both members of the public and publishers.
Historically, we've also used AWS SES to send emails, but that's being phased
out in favour of GOV.UK Notify.

[notify]: https://www.notifications.service.gov.uk/

We have two main services on GOV.UK Notify (six in total as we have a service
for each environment):

- **GOV.UK Emails**

  This service is used by Email Alert API only. It's used to send public-facing
  email updates about pieces of content on GOV.UK. It's our biggest sender of
  emails and regularly exceeds one million emails per day.

- **GOV.UK Publishing**

  This service is used by our publishing applications. It's used to send
  publisher-facing emails. The type of email can vary a lot, but a typical
  example might be to receive an email when a scheduled document on GOV.UK has
  been automatically published.

_In the future we may set up a new 'GOV.UK Public' service which is used to
send public-facing emails which haven't gone through Email Alert API._

## Accessing the dashboard

**[👉 Sign in to the GOV.UK Notify dashboard](https://www.notifications.service.gov.uk/sign-in)**

You can either use your own credentials (if you have them) or you can use the
credentials in [govuk-secrets][] (found in the `govuk-notify/2nd-line-support`
entry).

[govuk-secrets]: https://github.com/alphagov/govuk-secrets

## Receiving emails from GOV.UK Notify

GOV.UK Notify services have two modes: live and [trial][trial-mode]. Only our
production services are in live mode, the others are in trial mode. In this
mode emails will only be sent to members of the service or email address in the
allow-list, any request to send an email to another email address will fail.

[trial-mode]: https://www.notifications.service.gov.uk/using-notify/trial-mode

To receive emails in integration and staging through GOV.UK Notify, you should
add yourself to the service:

1. Choose the service in the appropriate environment and navigate to
   "Team members".

2. The members with the permission `Manage settings, team and usage` will be
   able to add you to this team.

**Note:** some of our applications, notably Email Alert API, has an extra level
of protection and [there is an extra step][email-alert-api-receive-emails]
before you can receive emails through Email Alert API.

[email-alert-api-receive-emails]: /manual/receiving-emails-from-email-alert-api-in-integration-and-staging.html