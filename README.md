# ErrorHandler

ErrorHandler provides a highly configurable and customizable error handler for any VFP application. It supports logging error information to a table, displaying an easy-to-understand dialog to the user, notifying support staff about the error via email or support ticket, and recovering from the error (either continuing in the application but not returning to the method that caused the error or terminating the application).

![](errordialog.png)

See ErrorHandler.docx for documentation.  

## Releases

### 2021-09-21

* You can now specify the name of the encryption library to use by changing the new cEncryptionLibrary property (set to "VFPEncryption71.dll" by default) if necessary.

### 2021-08-31

* It now lists in the log the cursors open in each datasession.

### 2021-08-23

* Made it use VFPEncryption71.dll since that support the C++ runtime used by VFP.

### 2021-07-20

* Initial release
