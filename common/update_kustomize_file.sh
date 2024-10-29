WRKDIR=`pwd`

help(){
   echo "Usage: <GROUP_NAME> <NEW_SERVICE> <ENV_NAME>"
   exit 0
}
GROUP_NAME=$1
SERVICE=$2
NEW_SERVICE=`echo $SERVICE | sed -e 's/_/-/g'`
echo "NEW_SERVICE: $NEW_SERVICE"

ENV_NAME=$3
test -z "$3" && help

test ! -e base && { echo "Path base not found" ; exit ; }

sed -i "/^images:/i - $NEW_SERVICE" overlays/$ENV_NAME/$GROUP_NAME/kustomization.yaml
