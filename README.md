A set of powershell functions:

- **Add purpose** is running every hour, picking all resource groups without a tag `purpose` and trying to apply a default tag based on resource group name.

- **AddExpiryDate** is running every hour,  picking all resource groups with a tag `purpose` set to `experiment`. If there's no expiry date, it's setting one to 14 days from now (can be configured in the app settings by modifying setting `DEFAULT_EXPIRY_DAYS`).

- **CleanupExpired** is running every day at UTC+8 (PDT 1AM), and removing all resource groups with an expiry date in the past.

# Deployment

Run `./provision.sh` in an Azure Cloud Shell, this will generate a pre-configured new function app in a resource group.