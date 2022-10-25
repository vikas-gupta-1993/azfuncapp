# azfuncapp
This is an API written in powershell to check status of Azure hosted wynsure Env

# API Code
funcappps\run.ps1 contains the code for API

# How to call?
You can call this API from your browser or from postman.
**Check VM Status** : You will need the **token** and name of reource group **rg**, ask integrators for this info
URL: https://viktestfuncps.azurewebsites.net/api/funcappps?code=#token#&rg=#rg#
**check Env Status**: Just input the **token** in the url: https://viktestfuncps.azurewebsites.net/api/funcappps?code=#token#&envstatus=true
