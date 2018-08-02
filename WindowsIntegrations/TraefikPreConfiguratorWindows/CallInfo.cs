// <copyright file="CallInfo.cs" company="Microsoft">
// Copyright (c) Microsoft. All rights reserved.
// </copyright>

namespace TraefikPreConfiguratorWindows
{
    using System.IO;
    using System.Runtime.CompilerServices;

    /// <summary>
    /// Holds information such as file name, line number, and method name of the caller.
    /// </summary>
    public struct CallInfo
    {
        /// <summary>
        /// Gets or sets the file name.
        /// </summary>
        public string FileName { get; set; }

        /// <summary>
        /// Gets or sets the file path.
        /// </summary>
        public string FilePath { get; set; }

        /// <summary>
        /// Gets or sets the line number.
        /// </summary>
        public int LineNumber { get; set; }

        /// <summary>
        /// Gets or sets the method name.
        /// </summary>
        public string MethodName { get; set; }

        /// <summary>
        /// Builds a CallInfo object with the necessary details for logging.
        /// </summary>
        /// <param name="memberName">CallerMemberName parameter.</param>
        /// <param name="sourceFilePath">CallerFilePath parameter.</param>
        /// <param name="sourceLineNumber">CallerLineNumber parameter.</param>
        /// <returns>A CallInfo object.</returns>
        public static CallInfo Site(
            [CallerMemberName] string memberName = "",
            [CallerFilePath] string sourceFilePath = "",
            [CallerLineNumber] int sourceLineNumber = 0)
        {
            CallInfo callInfo = new CallInfo
            {
                MethodName = memberName,
                FilePath = sourceFilePath,
                LineNumber = sourceLineNumber,
                FileName = Path.GetFileName(sourceFilePath),
            };
            return callInfo;
        }

        /// <summary>
        /// Returns a formatted string.
        /// </summary>
        /// <returns>A formatted string.</returns>
        public override string ToString()
        {
            return string.Format("{0}:{1}-{2}", this.FilePath, this.LineNumber, this.MethodName);
        }
    }
}
