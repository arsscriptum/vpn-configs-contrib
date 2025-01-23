
function Set-VpnConfigAuthenticationFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, Position=0)]
        [String]$Path,
        [Parameter(Mandatory=$True, Position=1)]
        [String]$AuthFilePath
    )
    try{
      # Get all .ovpn files in the directory
      $ovpnFiles = Get-ChildItem -Path $Path -Filter "*.ovpn" -File

      foreach ($file in $ovpnFiles) {
          # Read the content of each .ovpn file
          $fileContent = Get-Content -Path $file.FullName

          # Check if 'auth-user-pass' exists in the file
          $authUserPassLine = $fileContent | Where-Object { $_ -match '^auth-user-pass' }

          $lineCount = $fileContent.Length
          $authLineIndex = 0

          # Find the line number of '-----BEGIN CERTIFICATE-----'
          $certLineIndex = $fileContent.IndexOf('-----BEGIN CERTIFICATE-----')
          if ($certLineIndex -gt -1) {
            # The line with '-----BEGIN CERTIFICATE-----' exists
            $authLineIndex = $certLineIndex - 3
            if($authLineIndex -lt 0){$authLineIndex = 0}
          }

          if ($authUserPassLine) {
              # If there's a path after 'auth-user-pass', replace it with the new path
              if ($authUserPassLine -match '^auth-user-pass\s+(.+)$') {
                  $fileContent = $fileContent -replace "^auth-user-pass\s+.+$", "auth-user-pass $AuthFilePath"
              }
              else {
                  # If no path exists, add the authentication file path
                  $fileContent = $fileContent -replace "^auth-user-pass$", "auth-user-pass $AuthFilePath"
              }
          }
          else {
              # If 'auth-user-pass' doesn't exist, add it with the authentication file path

              $fileContent = $fileContent[0..$authLineIndex] + "auth-user-pass $authFilePath" + "`n" + $fileContent[($authLineIndex+1)..($lineCount-1)]
            
          }

          # Write the modified content back to the file
          Set-Content -Path $file.FullName -Value $fileContent
          Write-Host "Updated $($file.Name)"
      }

    }catch{
      write-error $_
    }
}
