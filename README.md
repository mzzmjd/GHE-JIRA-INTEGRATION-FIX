# GHE-JIRA-INTEGRATION-FIX
Script to identify issues in GitHub Enterprise (GHE) caused by JIRA creating wrong webhook.

[JSWSERVER-20298 - DVCS create incorrect webhook payload URL resulting 415 error](https://jira.atlassian.com/browse/JSWSERVER-20298)

## Script:
```org-fix-hooks.sh ORGANIZATION```

This script will scan through all the repositories in an organization and look at the webhooks.

You need to add the credentials for the integration account in a ```token.txt``` file

## More Information:  

This script was designed to work within a Git Bash environment. There is no dependency to install other software.


## Disclaimer:
No responsibility is taken for issues caused by this script. It is designed to help you and the wider JIRA / GitHub community.
