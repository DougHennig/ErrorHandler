* Get the "debug" mode setting.

llDebugMode = .F.

* Set up the global error handler. No need to declare it PUBLIC: it'll be
* available in all code called from this main program.

release oError
oError = newobject('SFErrorMgr', 'SFErrorMgr.vcx', '', 'My Application', .T., ;
	'oError')
with oError

* If we're in "debug" mode, display a developer's dialog when an error occurs.

	if llDebugMode
		.lShowDebug      = .T.
		.cMessageClass   = 'SFErrorMessage'
		.cMessageLibrary = 'SFErrorMgr.vcx'
	endif llDebugMode

* Set properties to customize the behavior.

	.cAppName    = 'My Application'
	.cVersion    = '1.0'
	.lScreenShot = .T.
		&& take a screen shot when an error occurs

* Set the current user's name and email address. These would likely be set once
* the user has logged in. If they aren't set, it isn't a problem because the
* user can specify the values in the error dialog.

	.cContact = 'Someone'
	.cEmail   = 'someone@someaddress.com'

* Get the email settings for the demo. To run this on your machine, put the
* correct settings into these properties.

	set library to VFPEncryption
	.cRecipient  = 'Put email address of recipient here'
	.cMailServer = 'Put address of mail server here'
	.nSMTPPort   = 'Put port number for mail server here'
	.cUserName   = 'Put user name for mail server here'
	.cPassword   = Encrypt('Put password for mail server here', .cUserName)

* Set the localizer settings (these are the defaults but are set here to show
* how to change them).

	.cLanguage      = 'English'
	.cResourceTable = 'Resource.dbf'
endwith

* Display the main form.

do form Sample

* Start the event loop. Note that we use a separate routine rather than an
* inline READ EVENTS statement here; it works better that way because we can
* set the cReturnToOnCancel property of the error object to the name of the
* routine containing the READ EVENTS statement.

do ReadEvents

* Clean up before we exit (some of this stuff is generic and not actually
* needed in this sample; e.g. we didn't open any tables so don't really need
* CLOSE DATABASES ALL).

clear events
close databases all
try
	clear all
catch
endtry
if version(2) = 2
	release oError
	on shutdown
	on error
	set path to
	clear
else
	quit
endif version(2) = 2

* The procedure containing the READ EVENTS statement. We'll set the cReturnToOn
* properties of the error object indicating where to go now that we're in the
* event loop.

procedure ReadEvents
oError.cReturnToOnCancel = 'ReadEvents'
oError.cReturnToOnQuit   = 'MASTER'
read events
