# ErrorHandler

ErrorHandler provides a highly configurable and customizable error handler for any VFP application. It supports logging error information to a table, displaying an easy-to-understand dialog to the user, notifying support staff about the error via email or support ticket, and recovering from the error (either continuing in the application but not returning to the method that caused the error or terminating the application).

![](errordialog.png)

See ErrorHandler.docx for documentation.  

## Releases

### 2021-08-23

* Made it use VFPEncryption71.dll since that support the C++ runtime used by VFP.

### 2021-07-20

* Initial release
