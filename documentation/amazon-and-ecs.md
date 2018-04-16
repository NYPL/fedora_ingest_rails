# Amazon & ECS Deployment Configuration

_This documentation is could be a rough guide for people looking to deploy web applications, with workers, on ECS.
It's not an exhaustive document of AWS resource settings & names, that would get out of date fast._

This application has 2 parts.

1. Web app/API containers that receive requests and insert records into the `delayed_jobs` table.
2. Worker containers to work the delayed_jobs.

To allow either to scale independently, we:

* Create 2 Task Definitions (One for the web app(s), the second will be for the worker(s))
* The cluster is composed of 2 services.
  * One for running the web application.
  * The second, for the workers.

This allows us to dial up or down each service's [desired count](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) depending on load/need.

## Application Load Balancer

Our EC2 instances are on a private network, but we handle web requests right?
That's why we need a load balancer. The load balancer is internet facing and
sends traffic to our machines on a private network. We need it to be an Application
Load Balancer to be able to do the port mapping required to handle multiple web applications running on
the same EC2 instance.

* Name should be `fedora-ingest-rails-[tier]`.
* It should be on a public subnet.
* It should have a security group named `fedora-ingest-rails-[tier]-loadbalancer`.
 * The security group should have 2 inbound rules that allow TCP (port 80) traffic from our internal IPs & VPN. (two broad CIDR blocks)

## Cluster

* Name should be `fedora-ingest-rails-[tier]`.
* It should be on a private subnet.
* It should be in a security group named `fedora-ingest-rails-ecs-cluster-[tier]`.
  * That VPC can allow SSH from our internal network.
  * It should allow TCP on ports (0-65535) from the security group of the load balancer. (this is for dynamic port binding see above)

## Web Application

### Task Definition

* Name should be `fedora-ingest-rails-web-application-[tier]`
* It should be given the task execution and task roles required to get its job done.
* Its container should have the name `fedora-ingest-rails-web-[tier]`
 * It should map container port 80 to host port 0. (When a container comes up it will expose its port 80 to an ephemeral port on the host but the Load Balancer sends traffic to the host's ephemeral port)
 * There's no need to overwrite the `Entry point` since this [Dockerfile's](../Dockerfile) default `CMD` starts the web app.

### Service

Since it's a big-ish deal if we have no web apps running we should always have one up.
An example of a service configuration that would ensure that is:

* Number of Tasks: 2
* Minimum Healthy Percent: 50
* Maximum percent: 100

When you create a service you'll be given a chance to:

* Set the load balancer to the Application Load Balancer created in the first step.
* Add the Task Definition's container to the load balancer.

## Worker

### Task Definition

* Name should be `fedora-ingest-rails-worker-[tier]`.
* It should be given the task execution and task roles required to get its job done.
* Its container should have the name `fedora-ingest-rails-worker-[tier]`
  * Since this is based on the same docker image as the web app, but doesn't run the web app,
  its `Entry point` should be overwritten to `/home/app/fedora_ingest_rails/bin/delayed_job, run`

### Service

To prevent zero workers from running you can also configure the service to look like:

* Number of Tasks: `[Whatever is appropriate]`
* Minimum Healthy Percent: 50
* Maximum percent: 100
