using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;

namespace TraefikPreConfiguratorWindows
{
    /// <summary>
    /// Performs Certificate related tasks.
    /// </summary>
    internal static class CertificateHandler
    {
        /// <summary>
        /// The default password used for PFX.
        /// </summary>
        private const string DefaultPfxPassword = "TraefikOnSF1@";

        /// <summary>
        /// Arguments to be used to extract .key out of .Pfx.
        /// </summary>
        private const string PrivateKeyExportArguments = "/c \"{0} pkcs12 -in \"\"{1}\"\" -nocerts -nodes -out \"\"{2}\"\" -passin pass:{3}\"";

        /// <summary>
        /// Arguments to be used to extract .crt out of .Pfx.
        /// </summary>
        private const string PublicKeyExportArguments = "/c \"{0} pkcs12 -in \"\"{1}\"\" -clcerts -nokeys -out \"\"{2}\"\" -passin pass:{3}\"";

        internal static async Task<ExitCode> ProcessAsync(string directoryPath, string certConfiguration, string keyVaultUri, string keyVaultClientId, string keyVaultClientSecret, string keyVaultClientCert)
        {
            if (string.IsNullOrEmpty(directoryPath))
            {
                Logger.LogError(CallInfo.Site(), "Directory path missing for the Certificate directory.");
                return ExitCode.DirectoryPathMissing;
            }

            if (string.IsNullOrEmpty(certConfiguration))
            {
                Logger.LogError(CallInfo.Site(), "Cert configuration missing. Please specify CertsToConfigure option");
                return ExitCode.InvalidCertConfiguration;
            }

            // 1. Initialize KeyVault Client if params were passed.
            KeyVaultClient keyVaultClient = null;
            if (!string.IsNullOrEmpty(keyVaultUri))
            {
                if (string.IsNullOrEmpty(keyVaultClientId))
                {
                    Logger.LogError(CallInfo.Site(), "If KeyVaultUri is specified, KeyVault ClientId must be specified");
                    return ExitCode.KeyVaultConfigurationIncomplete;
                }

                if (string.IsNullOrEmpty(keyVaultClientSecret) && string.IsNullOrEmpty(keyVaultClientCert))
                {
                    Logger.LogError(CallInfo.Site(), "If KeyVaultUri is specified, KeyVault ClientSecret or KeyVault ClientCert must be specified");
                    return ExitCode.KeyVaultConfigurationIncomplete;
                }

                if (!string.IsNullOrEmpty(keyVaultClientSecret))
                {
                    KeyVaultClient.AuthenticationCallback callback =
                        (authority, resource, scope) => GetTokenFromClientSecret(authority, resource, keyVaultClientId, keyVaultClientSecret);
                    keyVaultClient = new KeyVaultClient(callback);
                }
                else
                {
                    X509Certificate2 certificate = CertHelpers.FindCertificateByThumbprint(keyVaultClientCert);

                    if (certificate == null)
                    {
                        Logger.LogError(CallInfo.Site(), "Failed to find Client cert with thumbprint '{0}'", keyVaultClientCert);
                        return ExitCode.KeyVaultConfigurationIncomplete;
                    }

                    KeyVaultClient.AuthenticationCallback callback =
                        (authority, resource, scope) => GetTokenFromClientCertificate(authority, resource, keyVaultClientId, certificate);
                    keyVaultClient = new KeyVaultClient(callback);
                }
            }

            // 2. Figure all the certs which need processing.
            string[] certsToConfigure = certConfiguration.Split(',');
            string currentExeDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            string fullDirectoryPathForCerts = Path.Combine(currentExeDirectory, directoryPath);

            // 3. Process specified certs one by one.
            foreach (string certToConfigure in certsToConfigure)
            {
                // 3a. Split the cert configuration data to get actual details. This data is informat 
                // <CertNameOnDisk>;CertSource(LocalMachine or KeyVault);<CertIdentifier(SecretName or Thumbprint)>
                string[] certConfigurationParams = certToConfigure.Split(';');

                if (certConfigurationParams.Length != 3)
                {
                    Logger.LogError(CallInfo.Site(), "Invalid certificate configuration '{0}'. Cert configuration must be in format <CertFileName>;<CertSource>;<CertIdentifier>", certToConfigure);
                    return ExitCode.InvalidCertConfiguration;
                }

                var certConfig =
                    new { CertName = certConfigurationParams[0], CertSource = certConfigurationParams[1], CertIdentifier = certConfigurationParams[2] };

                // 3b. Depending on the source of Cert get the PFX for the certs dropped into the directory.
                if (certConfig.CertSource.Equals("MyLocalMachine", StringComparison.OrdinalIgnoreCase))
                {
                    ExitCode localMachineCertHandler = await LocalMachineCertHandler(certConfig.CertName, certConfig.CertIdentifier, fullDirectoryPathForCerts);

                    if (localMachineCertHandler != ExitCode.Success)
                    {
                        return localMachineCertHandler;
                    }
                }
                else if (certConfig.CertSource.Equals("KeyVault", StringComparison.OrdinalIgnoreCase))
                {
                    ExitCode keyVaultCertHandlerExitCode = await KeyVaultCertHandler(
                        certConfig.CertName,
                        certConfig.CertIdentifier,
                        fullDirectoryPathForCerts,
                        keyVaultClient,
                        keyVaultUri);

                    if (keyVaultCertHandlerExitCode != ExitCode.Success)
                    {
                        return keyVaultCertHandlerExitCode;
                    }
                }
                else
                {
                    Logger.LogError(CallInfo.Site(), "Unsupported Certificate source '{0}' for cert '{1}'", certConfig.CertSource, certConfig.CertName);
                    return ExitCode.UnsupportedCertSource;
                }

                // 3c. Convert PFX into .Key and .Crt. We are placing openssl next to this exe hence using current directory.
                ExitCode conversionExitCode = ConvertPfxIntoPemFormat(certConfig.CertName, fullDirectoryPathForCerts, currentExeDirectory);

                if (conversionExitCode != ExitCode.Success)
                {
                    return conversionExitCode;
                }

                // 3d. Delete the PFX as it is no longer needed.
                File.Delete(Path.Combine(fullDirectoryPathForCerts, certConfig.CertName + ".pfx"));
            }

            return ExitCode.Success;
        }

        /// <summary>
        /// Gets the token from client secret. This method is used as AuthCallback for KeyVault client.
        /// </summary>
        /// <param name="authority">The authority.</param>
        /// <param name="resource">The resource.</param>
        /// <param name="clientId">The client identifier.</param>
        /// <param name="clientSecret">The client secret.</param>
        /// <returns>Access token.</returns>
        private static async Task<string> GetTokenFromClientSecret(string authority, string resource, string clientId, string clientSecret)
        {
            var authContext = new AuthenticationContext(authority);
            var clientCred = new ClientCredential(clientId, clientSecret);
            var result = await authContext.AcquireTokenAsync(resource, clientCred);
            return result.AccessToken;
        }

        /// <summary>
        /// Gets the token from client certificate. This method is used as AuthCallback for KeyVault client.
        /// </summary>
        /// <param name="authority">The authority.</param>
        /// <param name="resource">The resource.</param>
        /// <param name="clientId">The client identifier.</param>
        /// <param name="certificate">The certificate.</param>
        /// <returns>Access token.</returns>
        private static async Task<string> GetTokenFromClientCertificate(string authority, string resource, string clientId, X509Certificate2 certificate)
        {
            var authContext = new AuthenticationContext(authority);
            var result = await authContext.AcquireTokenAsync(resource, new ClientAssertionCertificate(clientId, certificate));
            return result.AccessToken;
        }

        /// <summary>
        /// Extracts PFX from a local cert present in LocalMachine store under My.
        /// </summary>
        /// <param name="certificateName">Name of the certificate.</param>
        /// <param name="certificateThumbprint">The certificate thumbprint.</param>
        /// <param name="fullDirectoryPath">The full directory path to drop PFX at.</param>
        /// <returns>Exit code for the operation.</returns>
        private static Task<ExitCode> LocalMachineCertHandler(string certificateName, string certificateThumbprint, string fullDirectoryPath)
        {
            X509Certificate2 certificate = CertHelpers.FindCertificateByThumbprint(certificateThumbprint, StoreName.My, StoreLocation.LocalMachine);

            return Task.FromResult(SaveCertificatePrivateKeyToDisk(certificate, certificateName, fullDirectoryPath));
        }

        /// <summary>
        /// Extracts PFX from a certificate uploaded or generated from KeyVault. This does not support certs uploaded into KeyVault using secret.
        /// </summary>
        /// <param name="certificateName">Name of the certificate.</param>
        /// <param name="certificateSecretName">Secret name of the certificate. This is usually certificate name.</param>
        /// <param name="fullDirectoryPath">The full directory path to drop PFX at.</param>
        /// <param name="keyVaultClient">The key vault client.</param>
        /// <param name="keyVaultUrl">The key vault URL.</param>
        /// <returns>Exit code for the operation.</returns>
        private static async Task<ExitCode> KeyVaultCertHandler(
            string certificateName,
            string certificateSecretName,
            string fullDirectoryPath,
            KeyVaultClient keyVaultClient,
            string keyVaultUrl)
        {
            if (keyVaultClient == null)
            {
                Logger.LogError(CallInfo.Site(), "KeyVaultClient was not initialized. Make sure required params for KeyVault connection were passed");
                return ExitCode.KeyVaultConfigurationIncomplete;
            }

            if (string.IsNullOrEmpty(keyVaultUrl))
            {
                Logger.LogError(CallInfo.Site(), "Invalid KeyVault uri.");
                return ExitCode.KeyVaultConfigurationIncomplete;
            }

            SecretBundle certificateSecret;
            try
            {
                certificateSecret = await keyVaultClient.GetSecretAsync(keyVaultUrl, certificateSecretName);
            }
            catch (Exception ex)
            {
                Logger.LogError(CallInfo.Site(), ex, "Failed to get certificate with secret name '{0}' from key vault '{1}'", certificateSecretName, keyVaultUrl);
                return ExitCode.KeyVaultOperationFailed;
            }

            X509Certificate2 certificate;
            try
            {
                certificate = CertHelpers.GetCertificateFromBase64String(certificateSecret.Value);
            }
            catch (Exception ex)
            {
                Logger.LogError(CallInfo.Site(), ex, "Failed to decrypt certificate from keyvault. Make sure the cert was uploaded using Certificate tab and not uploaded as a secret");
                return ExitCode.FailedToDecodeCertFromKeyVault;
            }

            return SaveCertificatePrivateKeyToDisk(certificate, certificateName, fullDirectoryPath);
        }

        /// <summary>
        /// Saves the certificate private key in PFX format to disk.
        /// </summary>
        /// <param name="certificate">The certificate object.</param>
        /// <param name="certificateName">Name of the certificate (This is the name of the pfx file).</param>
        /// <param name="fullDirectoryPath">The full directory path.</param>
        /// <returns>Exit code for the operation.</returns>
        private static ExitCode SaveCertificatePrivateKeyToDisk(X509Certificate2 certificate, string certificateName, string fullDirectoryPath)
        {
            if (certificate == null)
            {
                Logger.LogError(CallInfo.Site(), "Failed to find certificate with name '{0}'", certificateName);
                return ExitCode.CertificateMissingFromSource;
            }

            if (!certificate.HasPrivateKey)
            {
                Logger.LogError(CallInfo.Site(), "Certificate with name '{0}' has missing Private Key", certificateName);
                return ExitCode.PrivateKeyMissingOnCertificate;
            }

            byte[] rawCertData = certificate.Export(X509ContentType.Pfx, DefaultPfxPassword);

            Directory.CreateDirectory(fullDirectoryPath);

            File.WriteAllBytes(Path.Combine(fullDirectoryPath, certificateName + ".pfx"), rawCertData);
            return ExitCode.Success;
        }

        /// <summary>
        /// Converts the PFX into pem format and extracts the Private key into .key and public in .crt format.
        /// </summary>
        /// <param name="certificateName">Name of the certificate.</param>
        /// <param name="certDirectoryPath">The full directory path for the PFX file. This is also the same path where the PEM and CRT files will be placed.</param>
        /// <param name="opensslExeDirectory">The openssl executable directory.</param>
        /// <returns>Exit code for the operation.</returns>
        private static ExitCode ConvertPfxIntoPemFormat(string certificateName, string certDirectoryPath, string opensslExeDirectory)
        {
            string opensslPath = Path.Combine(opensslExeDirectory, "openssl.exe");
            string pathToPfx = Path.Combine(certDirectoryPath, certificateName + ".pfx");

            string keyExtractionProcessArgs = string.Format(
                PrivateKeyExportArguments,
                opensslPath,
                pathToPfx,
                Path.Combine(certDirectoryPath, certificateName + ".key"),
                DefaultPfxPassword);

            // We have to start cmd.exe as openssl.exe exit is not read by Process class.
            Logger.LogVerbose(CallInfo.Site(), "Starting extraction of Private key for '{0}' using '{0}'", certificateName, opensslPath);
            Process exportPrivateKeyProcess = Process.Start("cmd", keyExtractionProcessArgs);
            exportPrivateKeyProcess.WaitForExit();
            Logger.LogVerbose(CallInfo.Site(), "Private key extraction for certificate '{0}' process completed with exit code '{1}'", certificateName, exportPrivateKeyProcess.ExitCode);

            string crtExtractionProcessArgs = string.Format(
                PublicKeyExportArguments,
                opensslPath,
                pathToPfx,
                Path.Combine(certDirectoryPath, certificateName + ".crt"),
                DefaultPfxPassword);

            // We have to start cmd.exe as openssl.exe exit is not read by Process class.
            Logger.LogVerbose(CallInfo.Site(), "Starting extraction of Public key from PFX using '{0}'", opensslPath);
            Process exportPublicKeyProcess = Process.Start("cmd", crtExtractionProcessArgs);
            exportPublicKeyProcess.WaitForExit();
            Logger.LogVerbose(CallInfo.Site(), "Public key extraction for certificate '{0}' process completed with exit code '{1}'", certificateName, exportPublicKeyProcess.ExitCode);

            if (!File.Exists(Path.Combine(certDirectoryPath, certificateName + ".key")))
            {
                Logger.LogError(CallInfo.Site(), "Private key extraction failed for certificate name '{0}'", certificateName);
                return ExitCode.PrivateKeyExtractionFailed;
            }

            if (!File.Exists(Path.Combine(certDirectoryPath, certificateName + ".crt")))
            {
                Logger.LogError(CallInfo.Site(), "Public key extraction failed for certificate name '{0}'", certificateName);
                return ExitCode.PublicKeyExtractionFailed;
            }

            return ExitCode.Success;
        }
    }
}
