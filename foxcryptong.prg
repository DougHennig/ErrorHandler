*========================================================================================
* Implements an easier to use interface to Microsoft's Cryptography Next Generation API.
*
* Copyright 2007-2022 Christof Wollenhaupt
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this 
* software and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy, modify, 
* merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
* permit persons to whom the Software is furnished to do so, subject to the following 
* conditions:
*
* The above copyright notice and this permission notice shall be included in all copies 
* or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
* PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
* CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
* OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*========================================================================================
Define Class foxCryptoNG as Custom

	*--------------------------------------------------------------------------------------
	* Various constants used
	*--------------------------------------------------------------------------------------
	#define BCRYPT_BLOCK_PADDING        0x00000001
	#define BCRYPT_PAD_NONE             0x00000001
	#define BCRYPT_PAD_PKCS1            0x00000002
	#define BCRYPT_PAD_OAEP             0x00000004
	#define BCRYPT_PAD_PSS              0x00000008
	#define BCRYPT_PAD_PKCS1_OPTIONAL_HASH_OID  0x00000010
	

*========================================================================================
* Initialize API
*========================================================================================
Procedure Init
	This.DeclareApiFunctions ()

*========================================================================================
* Creates an MD5 hash value. MD5 was used in the _Crypt.VCX library shipped by Microsoft 
* along with VFP 9 as part of the FoxPro Foundation Classes.
*
* CAUTION: This method is provided for backward compatibility only. MD5 is not a secure
*          hashing algorithm and should not be used in new development. Only use this
*          method if you have previously created and stored hashes and no possibility
*          to recalculate the hashes using a secure hashing algorithm.
*========================================================================================
Procedure Hash_MD5 (tcData)
	Local lcHash
	lcHash = This.HashData ("MD5", m.tcData)
Return m.lcHash

*========================================================================================
* Creates a SHA-1 hash value. This was the default when you created SHA hashes with the
* old Windows XP Crypto API or the _Crypt.VCX library shipped by Microsoft along with 
* VFP 9 as part of the FoxPro Foundation Classes.
*
* CAUTION: This method is provided for backward compatibility only. SHA-1 is not a secure
*          hashing algorithm and should not be used in new development. Only use this
*          method if you have previously created and stored hashes and no possibility
*          to recalculate the hashes using a secure hashing algorithm.
*========================================================================================
Procedure Hash_SHA1 (tcData)
	Local lcHash
	lcHash = This.HashData ("SHA1", m.tcData)
Return m.lcHash

*========================================================================================
* Creates a SHA-256 hash value.
*========================================================================================
Procedure Hash_SHA256 (tcData)
	Local lcHash
	lcHash = This.HashData ("SHA256", m.tcData)
Return m.lcHash

*========================================================================================
* Creates a SHA-512 hash value.
*========================================================================================
Procedure Hash_SHA512 (tcData)
	Local lcHash
	lcHash = This.HashData ("SHA512", m.tcData)
Return m.lcHash

*========================================================================================
* Generic routine for hashing binary data.
*========================================================================================
Procedure HashData (tcAlgorithm, tcData)

	*--------------------------------------------------------------------------------------
	* Stop when we encounter a failure
	*--------------------------------------------------------------------------------------
	Local llOK
	llOK = .T.

	*--------------------------------------------------------------------------------------
	* Get a handle to the hashing algorithm provider
	*--------------------------------------------------------------------------------------
	Local lnAlg
	lnAlg = 0
	If m.llOK
		llOK = BCryptOpenAlgorithmProvider( ;
			@lnAlg, Strconv(m.tcAlgorithm+Chr(0),5), NULL, 0 ) == 0
	EndIf

	*--------------------------------------------------------------------------------------
	* Determine how many bytes we need to store the hash object.
	*--------------------------------------------------------------------------------------
	Local lnSizeObj, lnData
	If m.llOK
		lnSizeObj = 0
		lnData = 0
		llOK = BCryptGetProperty( m.lnAlg, ;
			Strconv("ObjectLength"+Chr(0),5), @lnSizeObj, ;
			4, @lnData, 0 ) == 0
	EndIf
	
	*--------------------------------------------------------------------------------------
	* Determine length of hash value
	*--------------------------------------------------------------------------------------
	Local lnSizeHash
	If m.llOK
		lnSizeHash = 0
		llOK = BCryptGetProperty( m.lnAlg, ;
			Strconv("HashDigestLength"+Chr(0),5), ;
			@lnSizeHash, 4, @lnData, 0 ) == 0
	EndIf

	*--------------------------------------------------------------------------------------
	* Create the hash object
	*--------------------------------------------------------------------------------------
	Local lnHash, lcHashObj
	lnHash = 0
	If m.llOK
		lcHashObj = Space(m.lnSizeObj)
		llOK = BCryptCreateHash( m.lnAlg, @lnHash, ;
			@lcHashObj, m.lnSizeObj, NULL, 0, 0 ) == 0
	EndIf
	
	*--------------------------------------------------------------------------------------
	* To create the hash value we add data to the hash object. You can repeat this step 
	* as often as needed.
	*--------------------------------------------------------------------------------------
	If m.llOK
		llOK = BCryptHashData (m.lnHash, m.tcData, Len(m.tcData), 0) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* Signal the hash object that we are done. The algorithm then calculates the hash value
	* and returns it.
	*--------------------------------------------------------------------------------------
	Local lcHash
	If m.llOK
		lcHash = Space(m.lnSizeHash)
		llOK = BCryptFinishHash (m.lnHash, @lcHash, m.lnSizeHash, 0) == 0
	EndIf
	
	*--------------------------------------------------------------------------------------
	* Hashes are commonly viewed in the hex representation rather than the original 
	* binary form. As the final step we now convert the hash value into a hex string. Use
	* STRCONV() if you do need a binary value, instead.
	*--------------------------------------------------------------------------------------
	If m.llOK
		lcHash = Strconv (m.lcHash, 15)
	EndIf

	*--------------------------------------------------------------------------------------
	* Cleanup
	*--------------------------------------------------------------------------------------
	If m.lnAlg != 0
		BCryptCloseAlgorithmProvider (m.lnAlg, 0)
	EndIf 
	If m.lnHash != 0
		BCryptDestroyHash (m.lnHash)
	EndIf
	If not m.llOK
		lcHash = ""
	EndIf

Return m.lcHash

*========================================================================================
* Various API declarations
*========================================================================================
Procedure DeclareApiFunctions

	Declare Long BCryptOpenAlgorithmProvider ;
		in BCrypt.DLL ;
		Long @phAlgorithm, ;
		String pszAlgId, ;
		String pszImplementation, ;
		Long dwFlags

	Declare Long BCryptGetProperty in BCrypt.DLL ;
		Long hObject, ;
		String pszProperty, ;
    Long @pbOutput, ;
		Long cbOutput, ;
 		Long @pcbResult, ;
 		Long dwFlags

	Declare Long BCryptGetProperty in BCrypt.DLL As BCryptGetProperty_String ;
		Long hObject, ;
		String pszProperty, ;
		String @pbOutput, ;
		Long cbOutput, ;
 		Long @pcbResult, ;
 		Long dwFlags

	Declare Long BCryptCreateHash in BCrypt.DLL ;
		Long hAlgorithm, ;
		Long @phHash, ;
		String @pbHashObject, ;
		Long cbHashObject, ;
		String pbSecret, ;
		Long cbSecret, ;
		Long dwFlags

	Declare Long BCryptHashData in BCrypt.DLL ;
		Long hHash, ;
		String pbInput, ;
		Long cbInput, ;
		Long dwFlags

	Declare Long BCryptFinishHash in BCrypt.DLL ;
		Long hHash, ;
		String @pbOutput, ;
		Long cbOutput, ;
		Long dwFlags

	Declare Long BCryptDestroyHash in BCrypt.DLL ;
		Long hHash
	
	Declare Long BCryptCloseAlgorithmProvider ;
		in BCrypt.DLL ;
		Long hAlgorithm, ;
		Long dwFlags

	Declare Long BCryptDestroyKey in BCrypt.DLL ;
		Long hKey

	Declare long BCryptFinalizeKeyPair in BCrypt.DLL ;
		Long hKey, ;
		Long dwFlags
	
	Declare Long BCryptGenerateKeyPair in BCrypt.DLL ;
		long hAlgorithm, ;
		long @phKey, ;
		Long dwLength, ;
		Long dwFlags

	Declare Long BCryptExportKey in BCrypt.DLL ;
		Long hKey, ;
		Long hExportKey, ;
  	String pszBlobType, ;
  	String @pbOutput, ;
  	Long cbOutput, ;
  	Long @pcbResult, ;
  	Long dwFlags
  	
	Declare Long BCryptEncrypt in BCrypt.DLL ;
		Long hKey, ;
		String pbInput, ;
		Long cbInput, ;
		String pPaddingInfo, ;
		String @pbIV, ;
		Long cbIV, ;
		String @pbOutput, ;
		Long cbOutput, ;
		Long @pcbResult, ;
		Long dwFlags
	
	Declare Long BCryptImportKeyPair in BCrypt.DLL ;
		Long hAlgorithm, ;
		Long hImportKey, ;
		String pszBlobType, ;
		Long @phKey, ;
		String pbInput, ;
		Long cbInput, ;
		Long dwFlags
	
	Declare Long BCryptDecrypt in BCrypt.DLL ;
		Long hKey, ;
		String pbInput, ;
		Long cbInput, ;
		String pPaddingInfo, ;
		String @pbIV, ;
		Long cbIV, ;
		String @pbOutput, ;
		Long cbOutput, ;
		Long @pcbResult, ;
		Long dwFlags	
	
	Declare Long BCryptGenerateSymmetricKey in BCrypt.DLL ;
		Long hAlgorithm, ;
		Long @phKey, ;
		String pbKeyObject, ;
		Long cbKeyObject, ;
		String pbSecret, ;
		Long cbSecret, ;
		Long dwFlags
	
*========================================================================================
* Generates a pair of public and private keys using the RSA (PKCS #1) algorithm. The
* keys are returned in rcPrivate and rxPublic. These keys are binary data that is only
* meant to be used with CryptoNG.
*
* by default we generate an RSA key with 2048 bits. NIST considers this secure enough 
* until 2030. Keep in mind, that RSA is not the prefered public/private key algorithm, 
* as of 2019.
*
* You can pass a different length, but the length must be a multiple of 8. Common key
* length are 2048, 3072 and 4096. Do not use a key length less than 2048, as those
* are less secure. 
*
* Please note that longer key length take substially longer to generate. 
*========================================================================================
Procedure GenerateKeys_RSA (rcPrivate, rcPublic, tnKeyLength)
	
	*--------------------------------------------------------------------------------------
	* Stop when we encounter a failure
	*--------------------------------------------------------------------------------------
	Local llOK
	llOK = .T.
	
	*--------------------------------------------------------------------------------------
	* We either use the default key length of 2048 bits or the one that was given to us.
	*--------------------------------------------------------------------------------------
	Local lnKeyLength
	If Empty (m.tnKeyLength)
		lnKeyLength = 2048
	Else
		If m.tnKeyLength % 8 == 0
			lnKeyLength = m.tnKeyLength
		Else 
			llOK = .F.
		EndIf
	EndIf

	*--------------------------------------------------------------------------------------
	* RSA (PKCS #1) algorithm
	*--------------------------------------------------------------------------------------
	Local lnAlg
	lnAlg = 0
	If m.llOK
		llOK = BCryptOpenAlgorithmProvider( @lnAlg, Strconv("RSA",5)+Chr(0), NULL, 0 ) == 0
	EndIf

	*--------------------------------------------------------------------------------------
	* Generate a new key pair and finaalize it. We could change various key properties 
	* after generating a key pair. We can only use a key after we finalized it. Once it's
	* finalized, we can't change any of its properties.
	*
	*--------------------------------------------------------------------------------------
	Local lnKey
	lnKey = 0
	If m.llOK
		llOK = BCryptGenerateKeyPair (m.lnAlg, @lnKey, m.lnKeyLength, 0 ) == 0
		If m.llOK
			llOK = BCryptFinalizeKeyPair (lnKey, 0) == 0
		EndIf 
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* For encryption wee need to extract the public and the private key.
	*--------------------------------------------------------------------------------------
	If m.llOK
		rcPrivate = This.ExportKey( m.lnKey, "RSAPRIVATEBLOB" )
		rcPublic = This.ExportKey( m.lnKey, "RSAPUBLICBLOB" )
		if Empty(m.rcPrivate) or Empty(m.rcPublic)
			llOK = .F.
		EndIf
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* Cleanup
	*--------------------------------------------------------------------------------------
	If m.lnAlg != 0
		BCryptCloseAlgorithmProvider( m.lnAlg, 0 )
	EndIf 
	If m.lnKey != 0
		BCryptDestroyKey( m.lnKey )
	EndIf

Return m.llOK

*========================================================================================
* A key handle (tnKey) represents a key pair that contains a private and a public
* key. tcKey specifies which of these you want to export.
*========================================================================================
Procedure ExportKey (tnKey, tcKey)

	*--------------------------------------------------------------------------------------
	* Stop when we encounter a failure
	*--------------------------------------------------------------------------------------
	Local llOK
	llOK = .T.

	*--------------------------------------------------------------------------------------
	* Determine the key storage size in bytes
	*--------------------------------------------------------------------------------------
	Local lnSize
	If m.llOK
		lnSize = 0
		llOK = BCryptExportKey (m.tnKey, 0, Strconv(m.tcKey,5)+Chr(0), NULL, 0, @lnSize, ;
			0) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* Request the key
	*--------------------------------------------------------------------------------------
	Local lcKey
	If m.llOK
		lcKey = Space (m.lnSize)
		llOK = BCryptExportKey ( ;
			m.tnKey, 0, Strconv(m.tcKey,5)+Chr(0), @lcKey, Len(m.lcKey), @lnSize, 0) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* When we cannot export the key we return an empty value.
	*--------------------------------------------------------------------------------------
	If not m.llOK
		lcKey = ""
	EndIf 
	
Return m.lcKey

*========================================================================================
* Encrypts data using the RSA algorithm and PKCS1 padding.
*========================================================================================
Procedure Encrypt_RSA (tcData, tcPublicKey)

	*--------------------------------------------------------------------------------------
	* Stop when we encounter a failure
	*--------------------------------------------------------------------------------------
	Local llOK
	llOK = .T.

	*--------------------------------------------------------------------------------------
	* Get a handle to the RSA algorithm provider
	*--------------------------------------------------------------------------------------
	Local lnAlg
	lnAlg = 0
	If m.llOK
		llOK = BCryptOpenAlgorithmProvider (@lnAlg, Strconv("RSA",5)+Chr(0), NULL, 0 ) == 0
	EndIf

	*--------------------------------------------------------------------------------------
	* Create a new key pair and import the public key. This leaves us with a key pair
	* that does not have a private key. We can only use this key for encryption.
	*--------------------------------------------------------------------------------------
	Local lnKey
	lnKey = 0
	If m.llOK
		llOK = BCryptImportKeyPair ( ;
			m.lnAlg, 0, Strconv("RSAPUBLICBLOB",5)+Chr(0), @lnKey, ;
			m.tcPublicKey, Len(m.tcPublicKey), 0) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* RSA is a fixed length algorithm. Plain text´and cipher text have fixed length. We
	* use PKCS1 padding to pad shorter blocks. Determine the size of ciphertext.
	*--------------------------------------------------------------------------------------
	Local lnSize
	If m.llOK
		lnSize = 0
		llOK = BCryptEncrypt ( ;
			m.lnKey, m.tcData, Len(m.tcData), NULL, NULL, 0, NULL, 0, @lnSize, ;
			BCRYPT_PAD_PKCS1) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* Encrypt the data blob using PKCS1 padding
	*--------------------------------------------------------------------------------------
	Local lcEncrypted
	If m.llOK
		lcEncrypted = Space(m.lnSize)
		llOK = BCryptEncrypt ( ;
			m.lnKey, m.tcData, Len(m.tcData), NULL, NULL, 0, @lcEncrypted, ;
			Len(m.lcEncrypted), @lnSize, BCRYPT_PAD_PKCS1) == 0
	EndIf 

	*--------------------------------------------------------------------------------------
	* Cleanup
	*--------------------------------------------------------------------------------------
	If m.lnAlg != 0
		BCryptCloseAlgorithmProvider( m.lnAlg, 0 )
	EndIf 
	If m.lnKey != 0
		BCryptDestroyKey( m.lnKey )
	EndIf
	If not m.llOK
		lcEncrypted = ""
	EndIf 

Return m.lcEncrypted

*========================================================================================
* Decrypts data using the RSA algorithm and PKCS1 padding.
*========================================================================================
Procedure Decrypt_RSA (tcData, tcPrivateKey)

	*--------------------------------------------------------------------------------------
	* Stop when we encounter a failure
	*--------------------------------------------------------------------------------------
	Local llOK
	llOK = .T.

	*--------------------------------------------------------------------------------------
	* Get a handle to the RSA algorithm provider
	*--------------------------------------------------------------------------------------
	Local lnAlg
	lnAlg = 0
	If m.llOK
		llOK = BCryptOpenAlgorithmProvider (@lnAlg, Strconv("RSA",5)+Chr(0), NULL, 0 ) == 0
	EndIf

	*--------------------------------------------------------------------------------------
	* Create a new key pair and import the private key.
	*--------------------------------------------------------------------------------------
	Local lnKey
	lnKey = 0
	If m.llOK
		llOK = BCryptImportKeyPair ( ;
			m.lnAlg, 0, Strconv("RSAPRIVATEBLOB",5)+Chr(0), @lnKey, ;
			m.tcPrivateKey, Len(m.tcPrivateKey), 0) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* RSA is a fixed length algorithm. Plain text´and cipher text have fixed length. We
	* use PKCS1 padding to pad shorter blocks. Determine the size of ciphertext.
	*--------------------------------------------------------------------------------------
	Local lnSize
	If m.llOK
		lnSize = 0
		llOK = BCryptDecrypt ( ;
			m.lnKey, m.tcData, Len(m.tcData), NULL, NULL, 0, NULL, 0, @lnSize, ;
			BCRYPT_PAD_PKCS1) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* Decrypt the data blob using PKCS1 padding
	*--------------------------------------------------------------------------------------
	Local lcDecrypted
	If m.llOK
		lcDecrypted = Space(m.lnSize)
		llOK = BCryptDecrypt ( ;
			m.lnKey, m.tcData, Len(m.tcData), NULL, NULL, 0, @lcDecrypted, ;
			Len(m.lcDecrypted), @lnSize, BCRYPT_PAD_PKCS1) == 0
	EndIf 

	*--------------------------------------------------------------------------------------
	* Cleanup
	*--------------------------------------------------------------------------------------
	If m.lnAlg != 0
		BCryptCloseAlgorithmProvider( m.lnAlg, 0 )
	EndIf 
	If m.lnKey != 0
		BCryptDestroyKey( m.lnKey )
	EndIf
	If not m.llOK
		lcEncrypted = ""
	EndIf 

Return m.lcDecrypted

*========================================================================================
* Encrypts data with the symmetric AES algorithm. Data can be any length. However, the
* length of the key (password) defines the AES algorithm that is used. Only the following
* three key lengths are allowed:
*
*   16 chars = AES-128
*   24 chars = AES-192
*   32 chars = AES-256
*========================================================================================
Procedure Encrypt_AES (tcData, tcKey, tcIV)
	Local lcEncrypted
	If Pcount() > 2
		lcEncrypted = This.Encrypt_SymmetricBlock ("AES", m.tcData, m.tcKey, m.tcIV)
	Else
		lcEncrypted = This.Encrypt_SymmetricBlock ("AES", m.tcData, m.tcKey)
	EndIf
Return m.lcEncrypted 	

*========================================================================================
* Encrypts data the symmetric RC2 algorithm. Data can be any length. The length of the
* key should either be 
*
*    5 chars =  40 bit
*   16 chars = 128 bit
*
* CAUTION: This method is provided for backward compatibility only. RC2 is not a secure
*          encryption algorithm and should not be used in new development.
*========================================================================================
Procedure Encrypt_RC2 (tcData, tcKey, tcIV)
	Local lcEncrypted
	If Pcount() > 2
		lcEncrypted = This.Encrypt_SymmetricBlock ("RC2", m.tcData, m.tcKey, m.tcIV)
	Else
		lcEncrypted = This.Encrypt_SymmetricBlock ("RC2", m.tcData, m.tcKey)
	EndIf
Return m.lcEncrypted 	
	
*========================================================================================
* Encrypts data with any symmetric block cipher.
*========================================================================================
Procedure Encrypt_SymmetricBlock (tcAlgorithm, tcData, tcKey, tcIV)

	*--------------------------------------------------------------------------------------
	* Stop when we encounter a failure
	*--------------------------------------------------------------------------------------
	Local llOK
	llOK = .T.
	
	*--------------------------------------------------------------------------------------
	* Get a handle to the algorithm provider
	*--------------------------------------------------------------------------------------
	Local lnAlg
	lnAlg = 0
	If m.llOK
		llOK = BCryptOpenAlgorithmProvider( ;
			@lnAlg, Strconv(m.tcAlgorithm+Chr(0),5), NULL, 0 ) == 0
	EndIf

	*--------------------------------------------------------------------------------------
	* Turn the key into a symmetric key object that we can pass to the encryption funtion.
	*--------------------------------------------------------------------------------------
	Local lnKey
	lnKey = 0
	If m.llOK
		llOK = BCryptGenerateSymmetricKey ( ;
			m.lnAlg, @lnKey, NULL, 0, @tcKey, Len (m.tcKey), 0) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* We handle a block ciphers. The size of encrypted data is a multiple of the block size
	* which is based on the key length. We let the algorithm provider determine the actual
	* length.
	*--------------------------------------------------------------------------------------
	Local lnSize
	Local lcIV
	If m.llOK
		lnSize = 0
		If PCount() > 3
			m.lcIV = m.tcIV
			llOK = BCryptEncrypt ( ;
				m.lnKey, m.tcData, Len(m.tcData), NULL, @m.lcIV, Len(m.lcIV), NULL, 0, ;
				@lnSize, BCRYPT_BLOCK_PADDING) == 0
		Else
			llOK = BCryptEncrypt ( ;
				m.lnKey, m.tcData, Len(m.tcData), NULL, NULL, 0, NULL, 0, ;
				@lnSize, BCRYPT_BLOCK_PADDING) == 0
		EndIf
	EndIf

	*--------------------------------------------------------------------------------------
	* Now we can finally encrypt data
	*--------------------------------------------------------------------------------------
	Local lcEncrypted
	If m.llOK
		lcEncrypted = Space (m.lnSize)
		If PCount() > 3
			m.lcIV = m.tcIV
			llOK = BCryptEncrypt ( ;
				m.lnKey, m.tcData, Len(m.tcData), NULL, @m.lcIV, Len(m.lcIV), @lcEncrypted, ;
				Len(m.lcEncrypted), @lnSize, BCRYPT_BLOCK_PADDING) == 0
		Else
			llOK = BCryptEncrypt ( ;
				m.lnKey, m.tcData, Len(m.tcData), NULL, NULL, 0, @lcEncrypted, ;
				Len(m.lcEncrypted), @lnSize, BCRYPT_BLOCK_PADDING) == 0
		EndIf
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* Properly close any open handle. We return an empty varbinary value if any error 
	* occurred.
	*--------------------------------------------------------------------------------------
	If m.lnKey != 0
		BCryptDestroyKey (m.lnKey)
	EndIf
	If m.lnAlg != 0
		BCryptCloseAlgorithmProvider (m.lnAlg, 0)
	EndIf 
	If not m.llOK
		lcEncrypted = ""
	EndIf 

Return m.lcEncrypted

*========================================================================================
* Decrypts data with the symmetric AES Algorithm. The length of the key (password) 
* defines the AES algorithm that is used. Only the following three key lengths are 
* allowed:
*
*   16 chars = AES-128
*   24 chars = AES-192
*   32 chars = AES-256
*
* Important: The resulting value is always padded with blanks up to the block length used
*            by the algorithm. For plain text you can simply RTRIM() the result. For 
*            binary data you have to know the length of the original data before 
*            encryption.
*========================================================================================
Procedure Decrypt_AES (tcData, tcKey, tcIV)
	Local lcDecrypted
	If Pcount() > 2
		lcDecrypted = This.Decrypt_SymmetricBlock ("AES", m.tcData, m.tcKey, m.tcIV)
	Else
		lcDecrypted = This.Decrypt_SymmetricBlock ("AES", m.tcData, m.tcKey)
	EndIf
Return m.lcDecrypted

*========================================================================================
* Decrypts data the symmetric RC2 algorithm. Data can be any length. The length of the
* key should either be 
*
*    5 chars =  40 bit
*   16 chars = 128 bit
*
* CAUTION: This method is provided for backward compatibility only. RC2 is not a secure
*          encryption algorithm and should not be used in new development.
*========================================================================================
Procedure Decrypt_RC2 (tcData, tcKey, tcIV)
	Local lcDecrypted
	If Pcount() > 2
		lcDecrypted = This.Decrypt_SymmetricBlock ("RC2", m.tcData, m.tcKey, m.tcIV)
	Else
		lcDecrypted = This.Decrypt_SymmetricBlock ("RC2", m.tcData, m.tcKey)
	EndIf
Return m.lcDecrypted 	
	
*========================================================================================
* Decrypts data with a symmetric block based algorithm.
*========================================================================================
Procedure Decrypt_SymmetricBlock (tcAlgorithm, tcData, tcKey, tcIV)

	*--------------------------------------------------------------------------------------
	* Stop when we encounter a failure
	*--------------------------------------------------------------------------------------
	Local llOK
	llOK = .T.
	
	*--------------------------------------------------------------------------------------
	* Get a handle to the requested algorithm provider
	*--------------------------------------------------------------------------------------
	Local lnAlg
	lnAlg = 0
	If m.llOK
		llOK = BCryptOpenAlgorithmProvider( ;
			@lnAlg, Strconv(m.tcAlgorithm+Chr(0),5), NULL, 0 ) == 0
	EndIf
	
	*--------------------------------------------------------------------------------------
	* Turn the key into a symmetric key object that we can pass to the encryption funtion.
	*--------------------------------------------------------------------------------------
	Local lnKey
	lnKey = 0
	If m.llOK
		llOK = BCryptGenerateSymmetricKey ( ;
			m.lnAlg, @lnKey, NULL, 0, @tcKey, Len (m.tcKey), 0) == 0
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* We ask the algorithm provider for the length of our data.
	*--------------------------------------------------------------------------------------
	Local lnSize
	Local lcIV
	If m.llOK
		lnSize = 0
		If PCount() > 3
			m.lcIV = m.tcIV
			llOK = BCryptDecrypt ( ;
				m.lnKey, m.tcData, Len(m.tcData), NULL, @m.lcIV, Len(m.lcIV), NULL, 0, ;
				@lnSize, BCRYPT_BLOCK_PADDING) == 0
		Else
			llOK = BCryptDecrypt ( ;
				m.lnKey, m.tcData, Len(m.tcData), NULL, NULL, 0, NULL, 0, ;
				@lnSize, BCRYPT_BLOCK_PADDING) == 0
		EndIf 
	EndIf

	*--------------------------------------------------------------------------------------
	* Now we can finally decrypt data. We pad the buffer with blanks. CNG will not over-
	* write the last few bytes due to padding.
	*--------------------------------------------------------------------------------------
	Local lcDecrypted
	If m.llOK
		lcDecrypted = Space (m.lnSize)
		If PCount() > 3
			m.lcIV = m.tcIV
			llOK = BCryptDecrypt ( ;
				m.lnKey, m.tcData, Len(m.tcData), NULL, @m.lcIV, Len(m.lcIV), @lcDecrypted, ;
				Len(m.lcDecrypted), @lnSize, BCRYPT_BLOCK_PADDING) == 0
		Else
			llOK = BCryptDecrypt ( ;
				m.lnKey, m.tcData, Len(m.tcData), NULL, NULL, 0, @lcDecrypted, ;
				Len(m.lcDecrypted), @lnSize, BCRYPT_BLOCK_PADDING) == 0
		EndIf
	EndIf 
	
	*--------------------------------------------------------------------------------------
	* Properly close any open handle. We return an empty varbinary value if any error 
	* occurred.
	*--------------------------------------------------------------------------------------
	If m.lnKey != 0
		BCryptDestroyKey (m.lnKey)
	EndIf
	If m.lnAlg != 0
		BCryptCloseAlgorithmProvider (m.lnAlg, 0)
	EndIf 
	If not m.llOK
		lcDecrypted = ""
	EndIf 

Return m.lcDecrypted

EndDefine