# Marine Traffic Dashboard
Marine traffic dashboard

# Add marine traffic csv as 'ships.csv' next to app.R file

# Build image and push to GCP container registry:
*docker build -t <image-name> .*
*docker tag <image-name> eu.gcr.io/<project-name>/<image-name>:tag1*
*docker push eu.gcr.io/<project-name>/<image-name>:tag1*

# Deploy application in GCP Flexible environment
*gcloud app deploy --image-url eu.gcr.io/<project-name>/<image-name>:tag1 --version=1*

or run in RStudio