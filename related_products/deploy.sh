#!/bin/sh
#Install feeds tamper settings, patch for language feedback, install search system

# !!!!!
SITE_ROOT="/data/sites_php82/modular.dev"
LIST_MODULES="list_modules.txt"
### Main points
# before git: git --global --add safe.directory 
# Export current config before commit
# chown www:www after each copy
# chown www:www  Before export config
# After copy config fix domain
# Export current config before update config files
BASEDIR=$(dirname "$0")

read -p "Attention! Site URL is: ${SITE_ROOT}. Type yes" uservar

FILES=$(ls "$BASEDIR"/"$LIST_MODULES" 2>/dev/null)
if [ -n "$FILES" ]; then
	MODULES=$(cat  "$BASEDIR"/"$LIST_MODULES") 
	for MODULE in ${MODULES}; do
		echo "Module: "${MODULE}
		jexec -U www apache01 composer --working-dir="${SITE_ROOT}" require ${MODULE}
		MODULE=$(echo ${MODULE} | grep . | awk -F \: '{print $1}' | awk -F \/ '{print $2}')
		#MODULE=$(echo ${MODULE})
		echo "Enable module "${MODULE}
		jexec -U www apache01 drush -r "${SITE_ROOT}" pm:enable --yes "${MODULE}"
	
	done
else
    echo There are no modules in list to install.
fi

# patch modules
DIR_PATCHES_M=$(ls "$BASEDIR"/"modules" 2>/dev/null)
if [ -n "$DIR_PATCHES_M" ]; then
	cp -Rf "$BASEDIR"/modules/* "${SITE_ROOT}"/htdocs/modules/
	chown -R www:www "${SITE_ROOT}"/htdocs/modules/
	
	### modules/contrib
	PATCHES_MODULES_CONT=$(ls "$BASEDIR"/"modules/contrib" 2>/dev/null)
	if [ -n "$PATCHES_MODULES_CONT" ]; then
		LIST_PATCHES_MODULES=$(ls "$BASEDIR"/"modules/contrib" 2>/dev/null)
		#echo ASD "$LIST_PATCHES_MODULES"
	else
		echo There are no modules in directory \"modules/contrib\" to patch or install.
	fi
	### modules/custom
	PATCHES_MODULES_CUST=$(ls "$BASEDIR"/"modules/custom" 2>/dev/null)
	if [ -n "$PATCHES_MODULES_CUST" ]; then
		LIST_PATCHES_MODULES="$LIST_PATCHES_MODULES
$(ls "$BASEDIR"/"modules/custom" 2>/dev/null)"
		#echo ASD "$LIST_PATCHES_MODULES"
	else
		echo There are no modules in directory \"modules/custom\" to patch or install.
	fi	
	LIST_PATCHES_MODULES=$(echo "$LIST_PATCHES_MODULES" | sed 's/^[ \t]*//;s/[ \t]*$//')
	
	echo "$LIST_PATCHES_MODULES"
	cp -Rf "$BASEDIR"/modules/* "${SITE_ROOT}"/htdocs/modules/
	chown -R www:www "${SITE_ROOT}"/htdocs/modules/
	
	for MODULE in ${LIST_PATCHES_MODULES}; do
		echo "Module: "${MODULE}
		jexec -U www apache01 composer --working-dir="${SITE_ROOT}" require ${MODULE}
		MODULE=$(echo ${MODULE} | grep . | awk -F \: '{print $1}' | awk -F \/ '{print $2}')
		#MODULE=$(echo ${MODULE})
		echo "Enable module "${MODULE}
		jexec -U www apache01 drush -r "${SITE_ROOT}" pm:enable --yes "${MODULE}"	
	done
else
    echo There are no modules in directory \"modules\" to patch or install.
fi

# libraries
DIR_LIBS=$(ls "$BASEDIR"/"libraries" 2>/dev/null)
if [ -n "$DIR_LIBS" ]; then
	cp -Rf "$BASEDIR"/libraries/* "${SITE_ROOT}"/htdocs/libraries/
	chown -R www:www "${SITE_ROOT}"/htdocs/libraries/
else
    echo There are no libraries to install.
fi

# themes
DIR_THEMES=$(ls "$BASEDIR"/"themes" 2>/dev/null)
if [ -n "$DIR_THEMES" ]; then
	cp -Rf "$BASEDIR"/themes/* "${SITE_ROOT}"/htdocs/themes/
	chown -R www:www "${SITE_ROOT}"/htdocs/themes/
else
    echo There are no themes to install.
fi

# export current config
jexec -U www apache01 drush -r "${SITE_ROOT}" cex

# copy and import configs
cp -Rf "$BASEDIR"/config_sync/* "${SITE_ROOT}"/config/sync/
#/usr/local/sbin/searchreplace  '\/\/dev.mo' '\/\/mo' '/data/sites_php82/modular.prod/config/sync/*.yml'
chown -R www:www "${SITE_ROOT}"/config/sync
#jexec -U www apache01 drush -r "${SITE_ROOT}" cim --partial
jexec -U www apache01 drush -r "${SITE_ROOT}" cim
jexec -U www apache01 drush -r="${SITE_ROOT}" updatedb --yes
jexec -U www apache01 drush -r="${SITE_ROOT}" cache:rebuild

# Index search
#jexec -U www apache01 drush -r "${SITE_ROOT}" sapi-i products






