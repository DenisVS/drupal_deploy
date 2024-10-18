#!/bin/sh
# Universal script of deploy for Drupal sites

### Framework for Drupal sites on server.
# Requre Drush launcher
# Examples below
## Parameters
SITE_TYPE="prod"                                  # If you have a different versions with detail in names, you can assign them here
SITE_ROOT="/data/sites/php82/modular.$SITE_TYPE" # How looks the Site root from web server.
SITE_DIR="/zs2T1/sites/php82/modular.$SITE_TYPE" # Site directory from your POV
WEBSERVER_CMD_PREFIX="jexec -U www apache02 "    # If your commands on web server work in jail or another environment, set prefix here.
## /Parameters

BASEDIR=$(dirname "$0")
echo "Attention!"
echo "Site root on web server is: ${SITE_ROOT}"
echo "Site directory from your POV, is: ${SITE_DIR}"
read -p "Type \"yes\" if this is correct: " uservar

uservar=$(echo $uservar | grep -i yes)
if [ -z "$uservar" ]; then
  echo "Invalid parameter. STOP!"
  exit
fi

## Examples
# ${WEBSERVER_CMD_PREFIX}composer --working-dir="${SITE_ROOT}" require ${MODULE}
# ${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" pm:enable --yes "${MODULE}"
# cp -Rf "$BASEDIR"/libraries/* "${SITE_DIR}"/htdocs/libraries/
# chown -R www:www "${SITE_DIR}"/htdocs/libraries/
### /framework

LIST_MODULES="list_modules.txt"
LIST_unnecessary_configs="list_deleted_config.txt"
ADDITIONAL_CMD="additional_cmd.txt"
### Main points
# before git: git --global --add safe.directory
# Export current config before commit
# chown www:www after each copy
# chown www:www  Before export config
# After copy config fix domain
# Export current config before update config files

${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" cache:rebuild
set +x

FILES=$(ls "$BASEDIR"/"$LIST_MODULES" 2>/dev/null)
if [ -n "$FILES" ]; then
  MODULES=$(cat "$BASEDIR"/"$LIST_MODULES")
  for MODULE in ${MODULES}; do
    substring='-'
    if [ "$MODULE" != "${MODULE%"$substring"*}" ]; then
      MODULE=$(echo ${MODULE} | sed 's/\-//')
      SHORT_MODULE=$(echo ${MODULE} | grep . | awk -F \: '{print $1}' | awk -F \/ '{print $2}')
      echo "---------------- Disable module in Drush: ${SHORT_MODULE}"
      ${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" pm:uninstall --yes "${SHORT_MODULE}"
			set +x
      echo "--------------- Deinstall module by Composer: ${MODULE}"
      ${WEBSERVER_CMD_PREFIX}composer --working-dir="${SITE_ROOT}" remove ${MODULE}
    else
      echo "Install module by Composer: ${MODULE}"
      ${WEBSERVER_CMD_PREFIX}composer --working-dir="${SITE_ROOT}" require --with-all-dependencies ${MODULE}
      SHORT_MODULE=$(echo ${MODULE} | grep . | awk -F \: '{print $1}' | awk -F \/ '{print $2}')
      echo "Enable module with Drush: ${SHORT_MODULE}"
			echo "${WEBSERVER_CMD_PREFIX}drush -r ${SITE_ROOT} pm:enable --yes ${SHORT_MODULE}"
			set +x
      ${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" pm:enable --yes "${SHORT_MODULE}"
			set +x
    fi
  done
else
  echo There are no modules in list to install or deinstall.
fi



# patch modules
DIR_PATCHES_M=$(ls "$BASEDIR"/"modules" 2>/dev/null)
if [ -n "$DIR_PATCHES_M" ]; then
  cp -Rf "$BASEDIR"/modules/* "${SITE_DIR}"/htdocs/modules/
  chown -R www:www "${SITE_DIR}"/htdocs/modules/

  ### modules/contrib
  PATCHES_MODULES_CONT=$(ls "$BASEDIR"/"modules/contrib" 2>/dev/null)
  if [ -n "$PATCHES_MODULES_CONT" ]; then
    LIST_PATCHES_MODULES=$(ls "$BASEDIR"/"modules/contrib" 2>/dev/null)
    echo ASD "$LIST_PATCHES_MODULES"
    CONTRIB_MODULES=1
  else
    echo There are no modules in directory \"modules/contrib\" to patch or install.
    CONTRIB_MODULES=0
  fi
  ### modules/custom
  echo Basedir "$BASEDIR"
  PATCHES_MODULES_CUST=$(ls "$BASEDIR"/"modules/custom" 2>/dev/null)
  if [ -n "$PATCHES_MODULES_CUST" ]; then
    LIST_PATCHES_MODULES="$LIST_PATCHES_MODULES
$(ls "$BASEDIR"/"modules/custom" 2>/dev/null)"
  else
    echo There are no modules in directory \"modules/custom\" to patch or install.
  fi
  LIST_PATCHES_MODULES=$(echo "$LIST_PATCHES_MODULES" | sed 's/^[ \t]*//;s/[ \t]*$//')
  cp -Rf "$BASEDIR"/modules/* "${SITE_DIR}"/htdocs/modules/
  echo "$BASEDIR"'/modules/*' "${SITE_DIR}"'/htdocs/modules/'
  chown -R www:www "${SITE_DIR}"/htdocs/modules/

  for MODULE in ${LIST_PATCHES_MODULES}; do
    echo "Module: ${MODULE}"
    if [ "$CONTRIB_MODULES" = 1 ]; then
      ${WEBSERVER_CMD_PREFIX}composer --working-dir="${SITE_ROOT}" require ${MODULE}
    fi
    MODULE=$(echo ${MODULE} | grep . | awk -F \: '{print $1}' | awk -F \/ '{print $2}')
    echo "Enable module ${MODULE}"
    ${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" pm:enable --yes "${MODULE}"
		set +x
  done
else
  echo There are no modules in directory \"modules\" to patch or install.
fi

# libraries
DIR_LIBS=$(ls "$BASEDIR"/"libraries" 2>/dev/null)
if [ -n "$DIR_LIBS" ]; then
  cp -Rf "$BASEDIR"/libraries/* "${SITE_DIR}"/htdocs/libraries/
  chown -R www:www "${SITE_DIR}"/htdocs/libraries/
else
  echo There are no libraries to install.
fi

# themes
DIR_THEMES=$(ls "$BASEDIR"/"themes" 2>/dev/null)
if [ -n "$DIR_THEMES" ]; then
  cp -Rf "$BASEDIR"/themes/* "${SITE_DIR}"/htdocs/themes/
  chown -R www:www "${SITE_DIR}"/htdocs/themes/
else
  echo There are no themes to install.
fi

# export current config
echo "---------- Export current configs -----------------"
${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" cex
set +x

# Delete unnecessary config files
# $LIST_unnecessary_configs

FILES=$(ls "$BASEDIR"/"$LIST_unnecessary_configs" 2>/dev/null)
echo "---------- Delete unnecessary configs -----------------"
echo $LIST_unnecessary_configs
if [ -n "$FILES" ]; then
  CONFIGS=$(cat "$BASEDIR"/"$LIST_unnecessary_configs")
  for CONFIG in ${CONFIGS}; do
      echo "Delete config: ${CONFIG}"
			rm "${SITE_DIR}"/config/sync/"${CONFIG}"
  done
else
  echo There are no configs in list to delete.
fi



echo "---------- Import new configs -----------------"
# copy and import configs
cp -Rf "$BASEDIR"/config_sync/* "${SITE_DIR}"/config/sync/
#/usr/local/sbin/searchreplace  '\/\/dev.mo' '\/\/mo' '/data/sites_php82/modular.prod/config/sync/*.yml'
chown -R www:www "${SITE_DIR}"/config/sync
#${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" cim --partial
${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" cim
${WEBSERVER_CMD_PREFIX}drush -r="${SITE_ROOT}" updatedb --yes
${WEBSERVER_CMD_PREFIX}drush -r="${SITE_ROOT}" cache:rebuild
set +x

# Index search
#${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" sapi-i products


echo "------------- Run additional Drush commands---------"
#ADDITIONAL_CMD
FILES=$(ls "$BASEDIR"/"$ADDITIONAL_CMD" 2>/dev/null)
echo "---------- Delete unnecessary configs -----------------"
if [ -n "$FILES" ]; then
  COMMANDS=$(cat "$BASEDIR"/"$ADDITIONAL_CMD")
  for COMMAND in ${COMMANDS}; do
      echo "Run: ${COMMAND}"
			${WEBSERVER_CMD_PREFIX}drush -r "${SITE_ROOT}" "${COMMAND}"
			set +x
  done
else
  echo There are no configs in list to delete.
fi