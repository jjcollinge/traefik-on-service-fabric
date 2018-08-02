using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TraefikPreConfiguratorWindows
{
    public enum ExitCode
    {
        Success = 0,

        UnknownFailure = -1,

        DirectoryPathMissing = -2,

        KeyVaultConfigurationIncomplete = -3,

        InvalidCertConfiguration = -4,

        CertificateMissingFromSource = -5,

        PrivateKeyMissingOnCertificate = -6,

        KeyVaultOperationFailed = -7,

        FailedToDecodeCertFromKeyVault = -8,

        PrivateKeyExtractionFailed = -9,

        PublicKeyExtractionFailed = -10,

        UnsupportedCertSource = -11,
    }
}
