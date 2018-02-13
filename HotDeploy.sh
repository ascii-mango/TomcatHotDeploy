#/bin/bash

# . ~/.profile

export APP_ID=$1
export URL1="http://localhost:8257/myWebApp/mvc/"

export CHECK_URLS="$URL1"

export CATALINA_HOME=/opt/myWebApp/tomcat7/
export CATALINA_BASE=$CATALINA_HOME

echo CATALINA_HOME: $CATALINA_HOME
echo CATALINA_BASE: $CATALINA_BASE

export STOP_SCRIPT="$CATALINA_BASE/bin/shutdown.sh"
export START_SCRIPT="$CATALINA_BASE/bin/startup.sh"

echo STOP_SCRIPT: $STOP_SCRIPT
echo START_SCRIPT: $START_SCRIPT

export DEPLOY_SRC=~/autodeploy/tmp/${APP_ID}/${APP_ID}-*.war
export DEPLOY_WAR=${APP_ID}.war
export DEPLOY_DIR=${APP_ID}

echo DEPLOY_SRC: $DEPLOY_SRC
echo DEPLOY_WAR: $DEPLOY_WAR
echo DEPLOY_DIR: $DEPLOY_DIR

cd $CATALINA_BASE/webapps/
rm -f $CATALINA_BASE/webapps/${DEPLOY_WAR}

while [ -d "$CATALINA_BASE/webapps/${DEPLOY_DIR}" ]; do
  echo "$(date +'%Y-%m-%d_%H:%M:%S'): Waiting for ${DEPLOY_DIR} to undeploy..."
  sleep 5
done

echo "$(date +'%Y-%m-%d_%H:%M:%S'): === Undeploy completed."

${STOP_SCRIPT}
sleep 5

cp -ip $DEPLOY_SRC $CATALINA_BASE/webapps/${DEPLOY_WAR}

${START_SCRIPT}
sleep 5

while [ ! -d "$CATALINA_BASE/webapps/${DEPLOY_DIR}" ]; do
  echo "$(date +'%Y-%m-%d_%H:%M:%S'): Waiting for ${DEPLOY_DIR} hot-deploy to start..."
  sleep 5
done

echo "$(date +'%Y-%m-%d_%H:%M:%S'): === Hot-deploy started..."

mkdir -p /tmp/${APP_ID}/
TEMP_FILE=/tmp/${APP_ID}/${APP_ID}.$$

rm -f $TEMP_FILE

for url in $CHECK_URLS; do
	curl_check=FAIL
	echo "$(date +'%Y-%m-%d_%H:%M:%S'): Verifying url: $url"
	# Wait 6 * 5secs = 30secs for url to become accessible...
	for loop_count in 1 2 3 4 5 6 7 8; do
	  curl -k -L "$url" > $TEMP_FILE 2> /dev/null
	  grep 'myWebApp version:' $TEMP_FILE > /dev/null
	  result=$?
	  if [ "$result" == "0" ]; then
	    echo "$(date +'%Y-%m-%d_%H:%M:%S'): === url is OK: $url"
	    curl_check="OK"
		break;
	  fi
	  echo "$(date +'%Y-%m-%d_%H:%M:%S'): Waiting for hot-deploy to complete for: $url"
	  sleep 5
	done
	if [ "$curl_check" == "FAIL" ]; then
      echo "$(date +'%Y-%m-%d_%H:%M:%S'): === Hotdeploy FAILED for: $url"
	  exit 1
	fi
done

echo "$(date +'%Y-%m-%d_%H:%M:%S'): === Hotdeploy completed."