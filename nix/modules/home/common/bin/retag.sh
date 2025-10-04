docker pull "$1"
docker tag "$1" "$2"
docker push "$2"
