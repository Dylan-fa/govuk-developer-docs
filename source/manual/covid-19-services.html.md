---
owner_slack: "#govuk-corona-forms-tech"
title: COVID-19 Services
section: Services
layout: manual_layout
parent: "/manual.html"
last_reviewed_on: 2020-03-25
review_in: 1 month
---

We recently launched 2 new services:

- Offer coronavirus support from your business
- Get coronavirus support as an extremely vulnerable person

There is also an interactive voice response (IVR) automated phone
service provided by AWS.  This is for users who do not have access to
the internet.


## Offer coronavirus support from your business

This service allows businesses to tell us how they might be able to
help with the response to coronavirus.  This may include goods or
services such as medical equipment, hotel rooms or childcare.

- [Start page](https://www.gov.uk/coronavirus-support-from-business)
- [Service](https://coronavirus-business-volunteers.service.gov.uk/medical-equipment)
- [GitHub](https://github.com/alphagov/govuk-coronavirus-business-volunteer-form)


## Get coronavirus support as an extremely vulnerable person

This service allows citizens identified as vulnerable by the NHS to
tell us if they need help accessing essential supplies and support.
Users will have received a link to the service in a letter or a text
message from the NHS, or been advised by their GP to fill in the form.
They can fill the form in themselves, or someone else can fill it in
for them.

- [Start page](https://www.gov.uk/coronavirus-extremely-vulnerable)
- [Service](https://coronavirus-vulnerable-people.service.gov.uk/live-in-england)
- [GitHub](https://github.com/alphagov/govuk-coronavirus-vulnerable-people-form)


## Architecture

Both applications have a similar architecture of:

- **Framework:** Ruby on Rails
- **Database:** AWS RDS (business volunteering) and DynamoDB (vulnerable people)
- **Hosting:** PaaS
- **CDN:** AWS CloudFront
- **CI:** Travis
- **CD:** Concourse
- **Logging:** Sentry and Logit

### Application structure

Each application is a standard Rails application with:

- question pages, each has their own controller, view and route
- a check your answers page
- a confirmation ("Thank you") page
- ineligible pages (vulnerable people form only)
- a privacy page

To run one of the applications locally, see the README in the GitHub repo.


## Session and data storage

### Session storage

While the user is filling out the form, we use session storage to
store the user's data.

For the vulnerable people form, we store session data for 2 hours in an encrypted
cookie, persisted in the browser and sent back to the server for every
question.  Cookies have a limit of 4KB, so this approach could cause
errors if the user submits large inputs.

For the business volunteering form, we store the following for 2
hours:

- the session id in an encrypted cookie
- the session data in Redis

For the vulnerable people form we use a single session cookie to encrypt user responses.
This is also stored for 2 hours.

### Data storage

For both applications, when the user submits the form on the "Check
your answers" page, the application writes user data to the database.

The vulnerable people form application only has permission to write
items to the database. For security and privacy reasons, there's no
way to read or change already-submitted user data.

Developers should not have access to the production database for
the vulnerable people form application.

The business volunteering form application can both read and write
to it's database as the security and privacy requirements are lower.

Developers may treat data in the business volunteering form to the
same standards as any other GOV.UK personal data store, and are able
to access it for legitimate development duties.

## Hosting

### Paas

Both applications are hosted on GOV.UK Platform as a Service (PaaS) in
the Ireland region.  PaaS provides a scalable hosting platform based
on CloudFoundry managed by GDS.  You can read more in the [PaaS
technical documentation][paas-docs].

#### Get access

To get access, email govuk-senior-tech-members@digital.cabinet-office.gov.uk and ask for an invite to the
`govuk_development` organisation.  They need to give you a role that
lets you access both `staging` and `production` spaces and the
applications inside.

#### Log in

Before you start, [install the CloudFoundry CLI][cf-cli].

1. Log in with `cf login -a api.cloud.service.gov.uk --sso`
2. Select staging or production with `cf target -s <staging or production>`

Both applications are Rails applications, and use the
[`ruby_buildpack`][] to build and deploy to PaaS.  You can read more
about [managing PaaS applications][paas-managing] and [monitoring PaaS
applications][paas-monitoring].

#### Manage backing services

The business volunteer application uses PaaS's [Redis backing
service][paas-redis].  The backing service is attached to the
application by a setting in the `manifest.yml` file in the repository
root.

The JSON data in the `VCAP_SERVICES` environment variable exposes
settings and credentials for the backing service automatically.

### AWS

We have two AWS accounts (staging and production) for CDN and data
storage. They contain DynamoDB, IAM and CloudFront resources,
which were provisioned by Terraform in the [tech-ops-private
repository](techops-repo).

To log in to AWS:

1. [Install and set up the gds-cli](/manual/get-started.html#8-use-your-aws-access), then log in to the AWS Console with either:

   - `gds aws govuk-corona-data-staging -l` for staging
   - `gds aws govuk-corona-data-prod -l` for production


## Deployment

Deployment is managed via [TechOps shared Concourse][big-concourse].
CI/CD pipelines are configured under the `govuk-tools` team.  Any
changes to application code on the master branch are continuously
deployed to staging.  Smoke tests are set up to run on staging, if
these pass the applications are automatically deployed to production.
The smoke tests are the feature tests within the application
repository.

The Concourse deployment pipeline and task configuration for each
application is stored in the "concourse" directory at the root of each
repository.

Links to Concourse Pipelines:

- [`govuk-corona-business-volunteer-form`](https://cd.gds-reliability.engineering/teams/govuk-tools/pipelines/govuk-corona-business-volunteer-form)
- [`govuk-corona-vulnerable-people-form`](https://cd.gds-reliability.engineering/teams/govuk-tools/pipelines/govuk-corona-vulnerable-people-form)

For access login with your GitHub account, you need to be a part of
the GOV.UK Production team.  You'll also need to be on the VPN.

### Administering Pipelines

To administer pipelines you must have the `pipeline-operator` role.
Pipelines are administered using the `fly` CLI tool.  `fly` can be
downloaded directly from the Concourse dashboard using the links in
the bottom bottom right of the screen (you probably want to click the
apple). If that doesn't download an executable file, you can install with `brew cask install fly`.

To get started, firstly configure a target and log in:

```
fly --target cd-govuk-tools login --team-name govuk-tools --concourse-url https://cd.gds-reliability.engineering
```

Changes to the pipeline have to be applied manually using the
`set-pipeline` command.  To apply changes, run the following command
from the project root:

```
fly set-pipeline --pipeline <pipeline-name> --config concourse/pipeline.yml
```

Committing the changes to master will not update the pipeline
automatically.

GDS Reliability Engineering provide [further
documentation][big-concourse-docs].  More information on working with
Concourse and the Fly CLI can be found in [the official
documentation][concourse-docs].

### Zero-Downtime Deployment

The deployment tasks use the CloudFoundry v3 API commands in order to
support zero-downtime deployment and various new features.

When working with the cf cli tool, use the `v3` prefixed commands.
For example: `cf v3-apps`.

### Cancelling a failed deployment

Occasionally a zero-downtime deployment may fail.  This can occur if
the application fails to start, or the required number of app
instances cannot be created in time.  To cancel and roll back to the
previous deployment, run: `cf v3-cancel-zdt-push <app-name>`.

### Links to Staging

- [`govuk-coronavirus-business-volunteer-form`](https://govuk-coronavirus-business-volunteer-form-stg.cloudapps.digital/medical-equipment)
- [`govuk-coronavirus-vulnerable-people-form`](https://govuk-coronavirus-vulnerable-people-form-stg.cloudapps.digital/live-in-england)

These are protected by HTTP basic auth.  You can find the credentials
in govuk-secrets and get them by running:

```
cd ~/govuk/govuk-secrets/pass
./edit.sh 2ndline coronavirus-forms/creds
```

## Monitoring

There's a [Splunk dashboard][splunk] for both of these services.  To
access Splunk, you need to have the `GDS-006-GOVUK` permission on your
Google account.  To get this permission, raise an IT Helpdesk ticket
and post in `#cyber-security-help` to get them to confirm the request
is legitimate.

Application errors are sent to the GOV.UK hosted Sentry:

- [`govuk-coronavirus-business-volunteer-form`](https://sentry.io/organizations/govuk/issues/?project=5172100)
- [`govuk-coronavirus-vulnerable-people-form`](https://sentry.io/organizations/govuk/issues/?project=5170680)

These are under the GOV.UK Sentry account and you can sign in with
your Google Account.

Logs for both applications are streamed to Logit and can be found in
following dashboards:

[GOV.UK Production Corona Forms](https://logit.io/a/1c6b2316-16e2-4ca5-a3df-ff18631b0e74/s/04b46992-f653-4c14-965c-236e9a6c2777/kibana/access)
[GOV.UK Staging Corona Forms](https://logit.io/a/1c6b2316-16e2-4ca5-a3df-ff18631b0e74/s/7a0be476-6535-4544-8318-4c7a130948e8/kibana/access)

## Extracting form responses (business volunteering only)

Cabinet Office require data exports at regular intervals.  A
[recurring Concourse job](https://github.com/alphagov/govuk-coronavirus-business-volunteer-form/blob/5aed27777a22035b1b4f7ea9eafe612b105469a1/concourse/pipeline.yml#L99-L107)
exports the data to a S3 bucket each day between midnight and 1am.
Details of the bucket can be obtained using `cf services` and `cf env`.

Should further exports be required, there is a rake task to export
the data for a single day in JSON format.

```
cf v3-ssh govuk-coronavirus-business-volunteer-form
$ /tmp/lifecycle/shell
$ rake export:form_responses["<date>"]
```

Date to be included in the format 2020-03-26.

## Troubleshooting

### What things will call you

The GOV.UK PagerDuty will page on-call/2ndline if these applications go down. It's connected up to a Pingdom check in the GOV.UK account that checks if the first form page is up.

### Useful commands

> **Note:** Make sure to use the `v3-` commands for things like
> restarting or deploying apps, to do so in a zero-downtime way.

See the status of all the apps and how many instances are running:

```
cf v3-apps
```

Get the logs for an app:

```
cf logs <app-name> --recent
```

View detailed information about an app:

```
cf app <app-name>
```

Restart an app:

```
cf v3-restart <app-name>
```

Access a Postgres console (for business form only):

```
cf conduit govuk-coronavirus-business-volunteer-form-db -- psql
```

### Escalating to PaaS support

PaaS support contact details are in the [legacy opsmanual doc][legacy-opsmanual] under the
heading "PaaS Support (COVID-19 forms)".

[`ruby_buildpack`]: https://docs.cloud.service.gov.uk/deploying_apps.html#deploy-a-ruby-on-rails-app
[big-concourse]: https://cd.gds-reliability.engineering/
[big-concourse-docs]: https://reliability-engineering.cloudapps.digital/continuous-deployment.html#getting-started-with-concourse
[cf-cli]: https://docs.cloud.service.gov.uk/get_started.html#set-up-the-cloud-foundry-command-line
[concourse-docs]: https://concourse-ci.org/fly.html
[legacy-opsmanual]: https://docs.google.com/document/d/17XUuPaZ5FufyXH00S9qukl6Kf3JbJtAqwHR3eOBVBpI/edit
[paas-docs]: https://docs.cloud.service.gov.uk/
[paas-managing]: https://docs.cloud.service.gov.uk/managing_apps.html#managing-apps
[paas-monitoring]: https://docs.cloud.service.gov.uk/monitoring_apps.html#monitoring-apps
[paas-redis]: https://docs.cloud.service.gov.uk/deploying_services/redis/#redis
[splunk]: https://gds.splunkcloud.com/en-GB/app/gds-006-govuk/d006_coronavirus
[techops-repo]: https://github.com/alphagov/tech-ops-private/blob/master/reliability-engineering/terraform/deployments/corona-data-prod/account/iam.tf#L57-L184