# /bin/#!/bin/sh
#
# Pre-requiste
# ============
# the organization must exist
# Populate token.txt file with user name and personal access token.
# USER:TOKEN
#
# Usage
# =====
# org-fix-hooks.sh Organization
#
# Exit Codes
# ==========
# 0	Success
# 1	No Organization / No parameter passed to script
#

# Set the name of the Organization. It is passed as a parameter.
URL=GHE-LINK

# Set the name of the Organization. It is passed as a parameter.
ORG=$1

if [ $# -ne 1 ];
then
        echo "Invalid number of parameters."
        echo "Usage: ${0} ORGANIZATION"
        exit 1
else
        echo "Organization is ${ORG}"
fi

# Set up the user name and log file
# This needs to be run as the account used to integrate with JIRA
# We get the account details from a text file

TOKEN=`cat token.txt`
WORKDIR=`pwd`

echo "Starting ${ORG}"
echo "~~~~~~~~"

# We will start by getting an upto date list of the Repositories

rm -rf ${ORG}_repos_temp.txt ${ORG}_repos_sort.txt repos.txt ${ORG}_repos.txt
PAGE=0
CNT=100

echo "Building up list of repositories for ${ORG}"
while [ ${CNT} -eq 100 ]
do
	PAGE=`expr ${PAGE} + 1`
	curl -sS -u "${TOKEN}" -i "https://${URL}/api/v3/orgs/${ORG}/repos?per_page=100&page=${PAGE}" | grep clone_url > repos.txt
	CNT=`cat repos.txt | wc -l`

	cat repos.txt >> ${ORG}_repos.txt
done

awk -F"/" '{print $5}' ${ORG}_repos.txt > ${ORG}_repos_temp.txt
awk -F'.git"' '{print $1}' ${ORG}_repos_temp.txt > ${ORG}_repos_sort.txt
sort -r ${ORG}_repos_sort.txt > ${ORG}_repos.txt

rm -rf ${ORG}_repos_temp.txt ${ORG}_repos_sort.txt repos.txt
CNT=`cat ${ORG}_repos.txt | wc -l`

echo "Repository list complete. ${ORG} has ${CNT} repositories."

# We need to check that we have found some repositories
CNT=`cat ${ORG}_repos.txt | wc -l`

if [ ${CNT} -eq 0 ];
then
	echo "ERROR: No repositories found at https://${URL}/${ORG}. Aborting ..."
	exit 2
fi

echo "Starting work on identifying hooks"

for REPO in `cat ${ORG}_repos.txt`
do
    echo "Working on ${REPO}....."
    curl -sS -u "${TOKEN}" https://${URL}/api/v3/repos/${ORG}/${REPO}/hooks > output.txt

    if grep -q '\/repo\/sync' output.txt
    then
      # One of the hooks on the repo has the wrong link
      # So now we list the hooks out to a file
      grep '\"id\":' output.txt | awk -F': ' '{print $2}' | awk -F',' '{print $1}' > hooks.txt

      for HOOKID in `cat hooks.txt`
      do
        curl -sS -u "${TOKEN}" https://${URL}/api/v3/repos/${ORG}/${REPO}/hooks/${HOOKID} > hook-output.txt
        if grep -q '\/repo\/sync' hook-output.txt
        then
          HOOKURL=`grep '\/repo\/sync' hook-output.txt | awk -F'"' '{print $4}'`
          echo "Error with Hook in Repository ${REPO}"
          echo -e "\tHOOKID=${HOOKID}"
          echo -e "\tHOOKURL=${HOOKURL}"

          # Work out the correct url
          CORRECTURL=${HOOKURL%"/repo/sync"}/sync
          echo -e "\tCORRECTURL=${CORRECTURL}"

          # Now we can patch
          PARAM="{\"config\": {\"url\": \"${CORRECTURL}\"}}"
          curl -sS -X PATCH -u "${TOKEN}" https://${URL}/api/v3/repos/${ORG}/${REPO}/hooks/${HOOKID} -d "${PARAM}" > status.txt
          curl -sS -X POST -u "${TOKEN}" https://${URL}/api/v3/repos/${ORG}/${REPO}/hooks/${HOOKID}/tests >> status.txt
          echo "Fixed Hook in Repository ${REPO}"
        fi
      done
    fi
done

# Remove the repository list
rm -f ${ORG}_repos.txt status.txt hook-output.txt hooks.txt output.txt
