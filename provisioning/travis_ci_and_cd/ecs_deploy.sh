#! /bin/bash
# Deploy only if it's not a pull request
if [ -z "$TRAVIS_PULL_REQUEST" ] || [ "$TRAVIS_PULL_REQUEST" == "false" ] || [ "$TRAVIS_BRANCH" == "$HOT_DEPLOY_BRANCH" ]; then
  if [ "$TRAVIS_BRANCH" == "qa" ] || [ "$TRAVIS_BRANCH" == "nypl-dams-prod" ]; then
    case "$TRAVIS_BRANCH" in
      nypl-dams-prod)
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_PRODUCTION_NEW
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_PRODUCTION_NEW
        CLUSTER_NAME='fedora-ingest-rails-production'
        WEB_APP_SERVICE_NAME='fedora-ingest-rails-web-application-production'
        WORKER_SERVICE_NAME='fedora-ingest-rails-worker-production'
        ;;
      qa)
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_QA_NEW
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_QA_NEW
        CLUSTER_NAME='fedora-ingest-rails-qa'
        WEB_APP_SERVICE_NAME='fedora-ingest-rails-web-application-qa'
        WORKER_SERVICE_NAME='fedora-ingest-rails-worker-qa'
        ;;
    esac

    echo "Deploying $TRAVIS_BRANCH"
    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION aws ecs update-service --cluster $CLUSTER_NAME --region us-east-1 --service $WEB_APP_SERVICE_NAME --force-new-deployment
    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION aws ecs update-service --cluster $CLUSTER_NAME --region us-east-1 --service $WORKER_SERVICE_NAME --force-new-deployment
  else
    echo "Skipping deploy because it's not a deployable branch"
  fi
else
  echo "Skipping deploy because it's a PR"
fi
