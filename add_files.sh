#!/bin/bash

################################ Setting up Init scrips for trac ################################
touch /usr/local/bin/init_trac_repository.sh
cat <<copie > /usr/local/bin/init_trac_repository.sh
#!/bin/bash 
set –x
INI_ADMIN_PLUGIN=/usr/local/lib/python2.7/dist-packages/IniAdmin-0.3-py2.7.egg
TRAC_INI_ADMIN_PANEL_PLUGIN=/usr/local/lib/python2.7/dist-packages/TracIniAdminPanel-1.0.2-py2.7.egg

TRAC_ROOT=/var/local/trac/sites
SVN_ROOT=/var/local/svn/svn

TRAC_SVN_HOOK_SCRIPT=/usr/local/bin/trac-svn-hook.sh

SCRIPT_NAME="basename $0"
if [ $# -lt 1i ] || [ $# -gt 2 ];
then
        echo " $SCRIPT_NAME <clientname-projectcode> [<adminlogin>]

Parameters :
   <clientname-projectcode> forms the project name
   <adminlogin> is the login of an administrator to add to that instance of trac
Examples :
$SCRIPT_NAME Europerformance-StyleAnalytics
        => creates the project Europerformance-StyleAnalytics
$SCRIPT_NAME Iorga-Intranet bdamey
        => creates the project Iorga-Intranet and gives bdamey the admin rights"
        exit 1
fi

PROJECT_NAME=$1
ADMIN_LOGIN=$2

SVN_ENV=$SVN_ROOT/$PROJECT_NAME
TRAC_ENV=$TRAC_ROOT/$PROJECT_NAME
TRAC_ADMIN="trac-admin $TRAC_ENV"

# Create trap function which will stops the program if there is a problem with sub-calls
trap catch_error ERR;
function catch_error {
        echo "Problem occured, stopping $SCRIPT_NAME (last return code : $?)"
        exit 2
}

trap catch_int INT;
function catch_int {
        echo "$SCRIPT_NAME stopped with INT signal."
        exit 3
}

# Creation of the Trac repository
$TRAC_ADMIN initenv $PROJECT_NAME sqlite:db/trac.db svn $SVN_ROOT/$PROJECT_NAME

# Keep anonymous rights to add them to all future groups
ANONYMOUS_PERMISSIONS='$TRAC_ADMIN permission list anonymous | grep anonymous | cut -f 3 -d " "'
# Remove anonymous rights
$TRAC_ADMIN permission remove anonymous "*"
# Add anonymous permissions to authenticated one
#$TRAC_ADMIN permission add authenticated $ANONYMOUS_PERMISSIONS

# Add the "admin" group
$TRAC_ADMIN permission add admin TRAC_ADMIN

# Create the admin users
for USER in fprevost aogier $ADMIN_LOGIN
do
        $TRAC_ADMIN permission add $USER admin
done

# Create the devteam group
$TRAC_ADMIN permission add devteam $ANONYMOUS_PERMISSIONS TICKET_CREATE TICKET_MODIFY WIKI_CREATE WIKI_MODIFY

# Create the cdp group
$TRAC_ADMIN permission add cdp $ANONYMOUS_PERMISSIONS TICKET_ADMIN MILESTONE_ADMIN REPORT_ADMIN WIKI_ADMIN

# Create the ddp group
$TRAC_ADMIN permission add ddp $ANONYMOUS_PERMISSIONS TICKET_ADMIN MILESTONE_ADMIN REPORT_ADMIN WIKI_ADMIN CONFIG_VIEW

# Create the client group
$TRAC_ADMIN permission add client BROWSER_VIEW FILE_VIEW TICKET_VIEW TICKET_CREATE TICKET_APPEND TICKET_CHGPROP TICKET_MODIFY MILESTONE_VIEW ROADMAP_VIEW REPORT_VIEW WIKI_VIEW


# Add trac.ini editors
ln -nfs $INI_ADMIN_PLUGIN $TRAC_ENV/plugins/
ln -nfs $TRAC_INI_ADMIN_PANEL_PLUGIN $TRAC_ENV/plugins/

## Add SVN hooks
# Dealing with post-commit hook
SVN_POST_COMMIT_FOLDER=$SVN_ENV/hooks
SVN_POST_COMMIT_SCRIPT=$SVN_ENV/hooks/post-commit
# Verify that the folder exists
if [ ! -d $SVN_POST_COMMIT_FOLDER ]; then
        mkdir $SVN_POST_COMMIT_FOLDER
fi
# Create it if it doesn't exist
if [ ! -e $SVN_POST_COMMIT_SCRIPT ]; then
        touch $SVN_POST_COMMIT_SCRIPT
        echo "test"
cat <<EOF > $SVN_POST_COMMIT_SCRIPT
!/bin/sh
REPOS="\$1"
REV="\$2"
EOF
fi

# Add a link to the execution of trac-hook
cat <<EOF >> $SVN_POST_COMMIT_SCRIPT
# Calling the Trac hook
$TRAC_SVN_HOOK_SCRIPT \$REPOS \$REV
EOF

# Dealing with pre-revprop-change hook
SVN_PRE_REVPROP_CHANGE_SCRIPT=$SVN_ENV/hooks/pre-revprop-change
# Create it if it doesn't exist
if [ ! -e $SVN_PRE_REVPROP_CHANGE_SCRIPT ]; then
cat <<EOF > $SVN_PRE_REVPROP_CHANGE_SCRIPT
#!/bin/sh
REPOS="\$1"
REV="\$2"
USER="\$3"
PROPNAME="\$4"
ACTION="\$5"
EOF
fi

# Add a link to the execution of trac-hook
cat <<EOF >> $SVN_PRE_REVPROP_CHANGE_SCRIPT
# Calling the Trac hook
if [ "\$PROPNAME" = "svn:log" -o "\$PROPNAME" = "svn:author" ]; then
        $TRAC_SVN_HOOK_SCRIPT \$REPOS \$REV \$USER \$PROPNAME
fi
EOF
# Add the execution rights
chmod +x $SVN_POST_COMMIT_SCRIPT $SVN_PRE_REVPROP_CHANGE_SCRIPT
chown www-data $SVN_POST_COMMIT_SCRIPT $SVN_PRE_REVPROP_CHANGE_SCRIPT
## Now configure trac to use these hooks
# Enable CommitTicketUpdater
$TRAC_ADMIN config set components tracopt.ticket.commit_updater.committicketreferencemacro enabled
$TRAC_ADMIN config set components tracopt.ticket.commit_updater.committicketupdater enabled
# Disable auto syncing for "(default)" repository
$TRAC_ADMIN config set trac repository_sync_per_request ""
# Set all references to tickets in the update script
$TRAC_ADMIN config set ticket commit_ticket_update_commands.refs "<ALL>"
##

# Set correct rights
chown -R www-data $TRAC_ENV
copie

################################ Setting up hooks for Trac ################################
touch /usr/local/bin/trac-svn-hook.sh
cat <<copie > /usr/local/bin/trac-svn-hook.sh 
#!/bin/bash
TRAC_ROOT=/var/local/trac/sites 

# Script inspired from http://trac.edgewall.org/browser/trunk/contrib/trac-svn-hook 
REPOS="$1" 
REV="$2" 
USER="$3" 
PROPNAME="$4" 
#### Modified part #### 
# Try to set TRAC_ENV if it is not set, by looking at the svn REPOS value and knowing the base location of Trac sites 
if [ -z "$TRAC_ENV" ]; then 
TRAC_ENV_TEST="$TRAC_ROOT/'basename $REPOS'" 
if [ -d "$TRAC_ENV_TEST" ]; then 
TRAC_ENV=$TRAC_ENV_TEST 
fi 
fi 
#### End of modified part #### 

# -- Foolproofing 

if [ -z "$REPOS" -o -z "$REV" ]; then 
echo "Usage: $0 REPOS REV" 
exit 2 
fi 

if [ ! python -V 2>/dev/null ]; then 
echo "python is not in the PATH ($PATH), check PATH and LD_LIBRARY_PATH." 
exit 2 
fi 

if [ -z "$TRAC_ENV" ]; then 
echo "TRAC_ENV is not set." 
exit 2 
fi 

# -- Feedback 

echo "----" 

if [ -z "$USER" -a -z "$PROPNAME" ]; then 
EVENT="added" 
echo "Changeset $REV was added in $REPOS" 
else 
EVENT="modified" 
echo "Changeset $REV was modified by $USER in $REPOS" 
fi 

# -- Call "trac-admin ... changeset ... $REPOS $REV" for each Trac environment 

ifs=$IFS 
IFS=: 
if [ -n "$BASH_VERSION" ]; then # we can use Bash syntax 
if [[ ${BASH_VERSINFO[5]} = *cygwin ]]; then 
IFS=";" 
fi 
fi 
for env in $TRAC_ENV; do 
if [ -r "$env/VERSION" ]; then 
log=$env/log/svn-hooks-`basename $REPOS`.log 
nohup sh <<EOF >> $log 2>&1 & 
echo "Changeset $REV $EVENT" 
trac-admin $env changeset $EVENT $REPOS $REV && \ 
echo "OK" || echo "FAILED: see the Trac log" 
EOF 
else 
echo "$env doesn't seem to be a Trac environment, skipping..." 
fi 
done 
IFS=$ifs
copie

################################ Import archive script ################################
touch /usr/local/bin/import_project_archive
cat <<copie >/usr/local/bin/import_project_archive 
#!/bin/bash 
set -x 
TRAC_ROOT=/var/local/trac/sites 
SVN_ROOT=/var/local/svn/svn 
BASE_TMP_DIR=/tmp 
TRAC_BASE_URL=http:/$SERVER_NAME/trac 
INI_ADMIN_PLUGIN=/usr/local/lib/python2.7/dist-packages/IniAdmin-0.3-py2.7.egg 
TRAC_INI_ADMIN_PANEL_PLUGIN=/usr/local/lib/python2.7/dist-packages/TracIniAdminPanel-1.0.2-py2.7.egg 
SCRIPT_NAME='basename $0'
if [[ $# -lt 2 || $# -gt 3 ]]; then 
	echo " Usage : $SCRIPT_NAME <path_to_archive.7z> <admin_login> [<clientname-projectcode>] 
Parameters : 
<path_to_archive.7z> path to access to the archive we must import (must contain <clientname-projectcode> Trac folder inside, and <clientname-projectcode>.svn.dump file which contains the SVN dump of the project) 
<admin_login> is the login of the admin for that project (used for USVN) 
<clientname-projectcode> forms the project name. By default, it takes the basename of the archive. 
Examples : 
$SCRIPT_NAME /tmp/Europerformance-StyleAnalytics.7z fprevost 
=> Imports the project Europerformance-StyleAnalytics contained in the file /tmp/Europerformance-StyleAnalytics.7z 
$SCRIPT_NAME /tmp/import.7z fprevost Europerformance-StyleAnalytics 
=> Does the same but with file /tmp/import.7z "
	exit 1 
fi 
ARCHIVE_PATH=$1 
ADMIN_LOGIN=$2 
PROJECT_NAME=$3 
# Create trap function which will stops the program if there is a problem with sub-calls 
trap catch_error ERR; 
function catch_error { 
echo "Problem occured, stopping $SCRIPT_NAME (last return code : $?)" >&2 
exit 2 
} 
trap catch_int INT; 
function catch_int { 
echo "$SCRIPT_NAME stopped with INT signal." >&2 
exit 3 
} 
if [[ -z $PROJECT_NAME ]]; then 
PROJECT_NAME='basename $ARCHIVE_PATH'
fi 
ARCHIVE_PATH='readlink -f $ARCHIVE_PATH' 
# Checking user 
#if [[ "$USER" != "www-data" ]]; then 
# echo "You are not www-data. Please execute $SCRIPT_NAME as www-data (sudo -u www-data $SCRIPT_NAME)." >&2 
# exit 8 
#fi 
# Checking environments 
TRAC_ENV="$TRAC_ROOT/$PROJECT_NAME" 
if [[ -d $TRAC_ENV ]]; then 
echo "Trac environment '$TRAC_ENV' already exists. Stopping." >&2 
exit 4 
fi 
SVN_ENV="$SVN_ROOT/$PROJECT_NAME" 
if [[ -d $SVN_ENV ]]; then 
echo "SVN environment '$SVN_ENV' already exists. Stopping." >&2 
exit 5 
fi 
# Creating TMP_DIR 
TMP_DIR="$BASE_TMP_DIR/$SCRIPT_NAME.''openssl rand -hex 1'" 
sudo -u www-data mkdir $TMP_DIR 
# Registering a function to delete the TMP_DIR on exit 
trap clean_tmp_dir EXIT; 
function clean_tmp_dir { 
# Removing TMP_DIR 
echo "rm -rf $TMP_DIR" 
} 
# Extracting archive 
cd $TMP_DIR 
sudo -u www-data 7z x "$ARCHIVE_PATH" 
# Checking files 
TMP_TRAC_ENV="$TMP_DIR/$PROJECT_NAME" 
if [[ ! -d $TMP_TRAC_ENV ]]; then 
echo "Trac environment '$TMP_TRAC_ENV' not found in the archive. Stopping." >&2 
exit 6 
fi 
SVN_DUMP_FILE="$TMP_DIR/$PROJECT_NAME.svn.dump" 
if [[ ! -f $SVN_DUMP_FILE ]]; then 
echo "SVN dump file '$TMP_TRAC_ENV' not found in the archive. Stopping." >&2 
exit 7 
fi 
## Importing SVN backup 
# Create the SVN repository using USVN 
TMP_TRAC_ENV="$TMP_DIR/$PROJECT_NAME" 
sudo -u www-data init_svn_repository $PROJECT_NAME "'trac-admin $TMP_TRAC_ENV config get project descr'" $ADMIN_LOGIN 
# Import the dump 
sudo -u www-data svnadmin load $SVN_ENV < $SVN_DUMP_FILE 
## Importing Trac environment 
# Move the env to the right place 
mv "$TMP_TRAC_ENV" "$TRAC_ENV" 
TRAC_ADMIN="trac-admin $TRAC_ENV" 
# Upgrade it to current version 
$TRAC_ADMIN upgrade --no-backup 
# Update the documentation 
$TRAC_ADMIN wiki upgrade 
# Update link to correct SVN environment 
$TRAC_ADMIN config set trac repository_dir $SVN_ENV 
# Resync repository 
$TRAC_ADMIN repository resync '*' 
# Update links to correct URL for the web site 
$TRAC_ADMIN config set header_logo link $TRAC_BASE_URL/$PROJECT_NAME 
$TRAC_ADMIN config set trac base_url $TRAC_BASE_URL/$PROJECT_NAME 
# Add trac.ini editors 
ln -nfs $INI_ADMIN_PLUGIN $TRAC_ENV/plugins/ 
ln -nfs $TRAC_INI_ADMIN_PANEL_PLUGIN $TRAC_ENV/plugins/ 
# Calling the script which creates all the hooks in SVN environment and configure Trac to know the hooks are operationnal 
configure_trac_hooks_for_svn $PROJECT_NAME 
copie

################################ Project creation script ################################
touch /usr/local/bin/init_svn_repository
cat <<copie > /usr/local/bin/init_svn_repository
<?php

if (count($argv) <= 1 || count($argv) > 4) {
        print "Usage : $argv[0] <clientname-projectcode> <project_description> <admin_login>\n";
        exit (1);
}

require_once('/usr/local/lib/usvn/app/bootstrap.php');

// Creating project
$project_name = $argv[1];
$project_description = $argv[2];
$admin_login = $argv[3];
$create_group = 0;
$add_user_to_group = 0;
$create_admin = 1;
$create_svn_directories = 0;

$project = array();
$project["projects_name"] = $project_name;
$project["projects_description"] = $project_description;

USVN_Project::createProject($project, $admin_login, $create_group, $add_user_to_group, $create_admin, $create_svn_directories);

echo "Project $project_name created with $admin_login as admin\n";

?>
copie
