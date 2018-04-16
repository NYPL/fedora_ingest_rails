#! /bin/bash
# Deploy only if it's not a pull request
if [ -z "$TRAVIS_PULL_REQUEST" ] || [ "$TRAVIS_PULL_REQUEST" == "false" ] || [ "$TRAVIS_BRANCH" == "$HOT_DEPLOY_BRANCH" ]; then
  # Deploy only if we're testing the master branch
  if [ "$TRAVIS_BRANCH" == "development" ] || [ "$TRAVIS_BRANCH" == "qa" ] || [ "$TRAVIS_BRANCH" == "production" ] || [ "$TRAVIS_BRANCH" == "$HOT_DEPLOY_BRANCH" ]; then

    case "$TRAVIS_BRANCH" in
      production)
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_PRODUCTION
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_PRODUCTION
        CLUSTER_NAME=$CLUSTER_NAME_PRODUCTION
        SERVICE_NAME=$SERVICE_NAME_PRODUCTION
        WEB_APP_SERVICE_NAME="fedora-ingest-rails-web-application-production"
        WORKER_SERVICE_NAME="fedora-ingest-rails-worker-production"
        ;;
      qa)
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_PRODUCTION
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_PRODUCTION
        CLUSTER_NAME=$CLUSTER_NAME_QA
        SERVICE_NAME=$SERVICE_NAME_QA
        WEB_APP_SERVICE_NAME="fedora-ingest-rails-web-application-qa"
        WORKER_SERVICE_NAME="fedora-ingest-rails-worker-qa"
        ;;
      *)
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_DEVELOPMENT
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_DEVELOPMENT
        CLUSTER_NAME=$CLUSTER_NAME_DEVELOPMENT
        SERVICE_NAME=$SERVICE_NAME_DEVELOPMENT
        WEB_APP_SERVICE_NAME="fedora-ingest-rails-web-application"
        WORKER_SERVICE_NAME="fedora-ingest-rails-worker"
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
