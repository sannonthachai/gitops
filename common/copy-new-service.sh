#!/bin/sh
WRKDIR=`pwd`

help(){
   echo "Usage: <GROUP_NAME> <NEW_SERVICE> <ENV_NAME> [SUBGROUP_NAME]"
   exit 0
}
GROUP_NAME=$1
SERVICE=$2
ENV_NAME=$3
SUB_GROUP_NAME=${4:-""}
test -z "$3" && help

NEW_SERVICE=`echo $SERVICE | sed -e 's/_/-/g'`
if [ -n "$SUB_GROUP_NAME" ] ; then
  echo "SUB_GROUP_NAME:$SUB_GROUP_NAME"
  SERVICE_BASE_PATH=base/$GROUP_NAME/$SUB_GROUP_NAME/$NEW_SERVICE
  SERVICE_OVERLAYS_GROUP_PATH=overlays/$ENV_NAME/$GROUP_NAME
  SERVICE_OVERLAYS_PATH=$SERVICE_OVERLAYS_GROUP_PATH/$SUB_GROUP_NAME/$NEW_SERVICE
  RESOURCE_NAME=$SUB_GROUP_NAME/$NEW_SERVICE
  BASE_LINE="../../../../../$SERVICE_BASE_PATH"
  ARGOCD_SERVICE=$SUB_GROUP_NAME/$SERVICE
  DEFAULT_IMAGE=192.168.12.101:5050/$GROUP_NAME/$SUB_GROUP_NAME/$SERVICE:latest
  if [ "$SUB_GROUP_NAME" = "blockfint" ] ; then
    RPC_SUB_GROUP=bf
  else
    RPC_SUB_GROUP=oa
  fi
else
  SERVICE_BASE_PATH=base/$GROUP_NAME/$NEW_SERVICE
  SERVICE_OVERLAYS_GROUP_PATH=overlays/$ENV_NAME/$GROUP_NAME
  SERVICE_OVERLAYS_PATH=$SERVICE_OVERLAYS_GROUP_PATH/$NEW_SERVICE
  RESOURCE_NAME=$NEW_SERVICE
  BASE_LINE="../../../../$SERVICE_BASE_PATH"
  ARGOCD_SERVICE=$SERVICE
  DEFAULT_IMAGE=192.168.12.101:5050/$GROUP_NAME/$SERVICE:latest
fi

OS_INFO=`uname -o`
echo "NEW_SERVICE: $NEW_SERVICE"

test ! -e base && { echo "Path base not found" ; exit ; }
test -e $SERVICE_OVERLAYS_PATH && { echo "Path $SERVICE_OVERLAYS_PATH is exist then exit" ; exit ; }

echo mkdir -vp `dirname $SERVICE_BASE_PATH`
mkdir -vp `dirname $SERVICE_BASE_PATH`
echo mkdir -vp `dirname $SERVICE_OVERLAYS_PATH`
mkdir -vp `dirname $SERVICE_OVERLAYS_PATH`

echo 1. Copy files from template

cp -av common/base/template $SERVICE_BASE_PATH
cp -av common/overlays/template $SERVICE_OVERLAYS_PATH

echo 2. Replace string contains "RPC_NAME" to "$NEW_SERVICE"
grep -lr RPC_NAME $SERVICE_BASE_PATH > /tmp/1
grep -lr RPC_NAME $SERVICE_OVERLAYS_PATH >> /tmp/1
grep -lr RPC_REAL_NAME $SERVICE_OVERLAYS_PATH >> /tmp/1
while read line
do
  if [ "$OS_INFO" = "Darwin" ] ; then
   sed -i '' "s/RPC_NAME/$NEW_SERVICE/g" $line
   sed -i '' "s/RPC_REAL_NAME/$SERVICE/g" $line
   sed -i '' "s/RPC_PROJ/$GROUP_NAME/g" $line
   if [ -n "$SUB_GROUP_NAME" ] ; then
     sed -i ' ' "s/RPC_SUB_GROUP/$RPC_SUB_GROUP/g" $line
   fi
  else
   sed -i "s/RPC_NAME/$NEW_SERVICE/g" $line
   sed -i "s/RPC_REAL_NAME/$SERVICE/g" $line
   sed -i "s/RPC_PROJ/$GROUP_NAME/g" $line
   if [ -n "$SUB_GROUP_NAME" ] ; then
     sed -i "s/RPC_SUB_GROUP/$RPC_SUB_GROUP/g" $line
   fi
  fi
done < /tmp/1

echo 3. Review all new configurations
find $SERVICE_BASE_PATH
find $SERVICE_OVERLAYS_PATH

echo 4. Add $NEW_SERVICE to $SERVICE_OVERLAYS_GROUP_PATH/kustomization.yaml
if [ "$OS_INFO" = "Darwin" ] ; then
  echo "BASE_LINE: $BASE_LINE"
  sed -i '' "/^images:/i - $RESOURCE_NAME" $SERVICE_OVERLAYS_GROUP_PATH/kustomization.yaml
  sed -i '' -e "s|.*base.*|- $BASE_LINE|g" $SERVICE_OVERLAYS_PATH/kustomization.yaml
else
  echo "BASE_LINE: $BASE_LINE"
  sed -i "/^images:/i - $RESOURCE_NAME" $SERVICE_OVERLAYS_GROUP_PATH/kustomization.yaml
  sed -i "s|.*base.*|- $BASE_LINE|g" $SERVICE_OVERLAYS_PATH/kustomization.yaml
fi
cd $SERVICE_OVERLAYS_GROUP_PATH
kustomize edit set image ${SERVICE}-image=$DEFAULT_IMAGE
cd $WRKDIR

echo 5. Run kustomize build to check syntax
kustomize build $SERVICE_OVERLAYS_GROUP_PATH

if [ $? -ne 0 ] ; then
  echo "Syntax error then exit"
  exit 0
fi

git pull
git add $SERVICE_BASE_PATH
git add $SERVICE_OVERLAYS_PATH
git add $SERVICE_OVERLAYS_GROUP_PATH/kustomization.yaml
echo "$ARGOCD_SERVICE" >> systems/argocd/$ENV_NAME/$GROUP_NAME/service_list

#echo 6. Update argocd
#mkdir -p systems/argocd/$ENV_NAME/$GROUP_NAME
#sh systems/argocd/append.sh $ENV_NAME $GROUP_NAME > systems/argocd/$ENV_NAME/$GROUP_NAME/$GROUP_NAME.yaml
#git add systems/argocd/$ENV_NAME
#git status
#git commit -a -m "feat: add new service $NEW_SERVICE"
#git log --stat -n 1

echo "Run apply systems/argocd/sit/iden.yaml"
echo kubectl -n argocd apply -f systems/argocd/$ENV_NAME/$GROUP_NAME.yaml
