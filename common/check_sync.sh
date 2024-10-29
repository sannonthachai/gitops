while read IMAGE_NAME
do

  test -z "$IMAGE_NAME" && { echo "Missing IMAGE_NAME($IMAGE_NAME}" ; continue ; }
  name=`echo $IMAGE_NAME | awk '{print $1}'`
  VERSION=`echo $IMAGE_NAME | awk '{print $2}'`

  registry=$(yq ".images[] | select(.name == \"*$name-image*\") | .newTag" ../overlays/sit/iden/kustomization.yaml)
  if [ "$registry" != "$VERSION" ]; then
    echo "$name $VERSION --> $registry"
  fi

done < version2