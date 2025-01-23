#+--------------------------------------------------------------------------------+
#|                                                                                |
#|   ExpressVpnConfigurations.ps1                                                 |
#|                                                                                |
#+--------------------------------------------------------------------------------+
#|   Guillaume Plante <codegp@icloud.com>                                         |
#|   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      |
#+--------------------------------------------------------------------------------+

[CmdletBinding(SupportsShouldProcess)]
param()


function Register-HtmlAgilityPack{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$False)]
        [string]$Path
    )
    begin{
        if([string]::IsNullOrEmpty($Path)){
            $Path = "{0}\lib\{1}\HtmlAgilityPack.dll" -f "$PSScriptRoot", "$($PSVersionTable.PSEdition)"
        }
    }
    process{
      try{
        if(-not(Test-Path -Path "$Path" -PathType Leaf)){ throw "no such file `"$Path`"" }
        if (!("HtmlAgilityPack.HtmlDocument" -as [type])) {
            Write-Verbose "Registering HtmlAgilityPack... " 
            add-type -Path "$Path"
        }else{
            Write-Verbose "HtmlAgilityPack already registered " 
        }
      }catch{
        throw $_
      }
    }
}


function Invoke-ExtractVpnConfigFileLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [ValidateRange(1,5)]
        [int]$ContinentId = 1
    )

    try{

        Add-Type -AssemblyName System.Web  

        $Null = Register-HtmlAgilityPack 

        $Ret = $False

        $HtmlSourceFilePath = (Resolve-Path -Path "$PSScriptRoot\..\html\source.html").Path
        $HtmlContent = Get-Content -Path "$HtmlSourceFilePath" -Raw

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        
        $HtmlNode = $HtmlDoc.DocumentNode
        [System.Collections.ArrayList]$List = [System.Collections.ArrayList]::new()
        $HashTable = @{}
        For($i=1;$i -lt 99;$i++){
            $XNodeAddr = "/html/body/div[1]/div/div[1]/div[2]/div[1]/div[2]/div/div[17]/div[4]/div/ol/div[2]/div[1]/div[{0}]/ul/li[{1}]/a" -f $ContinentId,$i
            try{
                $ResultNode = $HtmlNode.SelectNodes($XNodeAddr)
                [string]$htmlString = $ResultNode.OuterHtml
                [string]$Name = $ResultNode.InnerHtml
                # Regex patterns
                $clusterIdPattern = 'cluster_id=(\d+)'
                $cityPattern = '>([^<]+)<'

                # Extract cluster_id
                if ($htmlString -match $clusterIdPattern) {
                    $clusterId = $matches[1]
                } else {
                    $clusterId = "Not Found"
                }

                # Extract city name
                if ($htmlString -match $cityPattern) {
                    $cityName = $matches[1]
                } else {
                    $cityName = "Not Found"
                }

                if("$cityName" -ne "Not Found"){
                    $filename = $cityName.Replace(' ', '_')

                    $HashTable.Add("$clusterId", "$cityName")
                    [PsCustomObject]$o = [PsCustomObject]@{
                        Name = "$cityName"
                        File = "$filename"
                        ClusterId = $clusterId
                    }
                    [void]$List.Add($o)
                }
                

            }catch{
                break;
            }

        }

        return $List
        
    }catch{
        Write-Verbose "$_"
        Write-Host "Error Occured. Probably Invalid Page Id" -f DarkRed
    }
    return $Null
}



function Get-UserPassTest{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try{

        $CredzId = 'expressvpn_autologin_creds'
        $AuthData = Get-appCredentials $CredzId
        if(-not($c)){

            $CurrentPath = (Resolve-Path -Path "$PSScriptRoot").Path
            $VpnLoginLandingScript = (Resolve-Path -Path "$PSScriptRoot\VpnLoginLandingPage.ps1").Path
            . "$VpnLoginLandingScript"

            Add-Type -AssemblyName System.Web  

            $Null = Register-HtmlAgilityPack 

            $Ret = $False

            $c = get-appCredentials 'exprexxvpn-web'
            if(-not($c)){
                $c = Get-Credential -Message "Enter ExpressVPN Account (www) Credentialz" -Title 'EXPRESSVPN CREDENTIALS'
            }
            $u = $c.UserName
            $p = $c.GetNetworkCredential().Password
            $HtmlContent = Get-VpnLoginLandingPage $u $p

            [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
            $HtmlDoc.LoadHtml($HtmlContent)
            
            $HtmlNode = $HtmlDoc.DocumentNode

            $UsernameXPath = '/html[1]/body[1]/div[1]/div[1]/div[2]/div[2]/div[1]/div[2]/div[1]/div[17]/div[4]/div[1]/ol[1]/div[1]/div[1]/div[1]/p[2]'
            $PasswordXPath = '/html[1]/body[1]/div[1]/div[1]/div[2]/div[2]/div[1]/div[2]/div[1]/div[17]/div[4]/div[1]/ol[1]/div[1]/div[1]/div[1]/p[4]'
            $UsernameNode = $HtmlNode.SelectNodes($UsernameXPath)
            $PasswordNode = $HtmlNode.SelectNodes($PasswordXPath)

            if(-not($UsernameNode)){
                throw "cannot find username in vpn config  page"
            }
            if(-not($PasswordNode)){
                throw "cannot find password in vpn config  page"
            }

            $VpnUserId = $UsernameNode.InnerText
            $VpnPasswordId = $PasswordNode.InnerText

            $ret = Register-appCredentials 'expressvpn_autologin_creds' -Username $VpnUserId -Password $VpnPasswordId
            
            $AuthData = Get-appCredentials $CredzId
            return $AuthData
        }
        return $AuthData
    }catch{
        Write-Verbose "$_"
        Write-Host "Error Occured. Probably Invalid Page Id" -f DarkRed
    }
    return $Null
}




function Save-VpnConfigurationFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, Position=0)]
        [System.Collections.ArrayList]$Links
    )



    $Credz =  Get-AppCredentials 'exprexxvpn-credz'
    if(-not($Credz)){
        $Credz = Get-Credential -Message "Enter ExpressVPN Account (www) Credentialz" -Title 'EXPRESSVPN CREDENTIALS'
    }
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
    $Res = Invoke-WebRequest -Uri "https://www.expressvpn.com/setup"  -Authentication Basic -Credential $Credz -SkipCertificateCheck -AllowUnencryptedAuthentication -WebSession $session

    $Source = "web"
    $Os = "linux"
    $ClusterId = 248
    $Code = ""

    

    $headerz = @{
      "authority"="www.expressvpn.com"
      "method"="GET"
      "path"=""
      "scheme"="https"
      "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
      "accept-encoding"="gzip, deflate, br, zstd"
      "accept-language"="en-US,en;q=0.9"
      "cache-control"="no-cache"
      "pragma"="no-cache"
      "priority"="u=0, i"
      "referer"="https://www.expressvpn.com/setup"
      "sec-ch-ua"="`"Not A(Brand`";v=`"8`", `"Chromium`";v=`"132`", `"Brave`";v=`"132`""
      "sec-ch-ua-mobile"="?0"
      "sec-ch-ua-platform"="`"Windows`""
      "sec-fetch-dest"="document"
      "sec-fetch-mode"="navigate"
      "sec-fetch-site"="same-origin"
      "sec-fetch-user"="?1"
      "sec-gpc"="1"
      "upgrade-insecure-requests"="1"
    }



    $CurrentPath = (Resolve-Path -Path "$PSScriptRoot").Path
    $ScriptsPath = (Resolve-Path -Path "$PSScriptRoot\..").Path
    $SavePath = Join-Path $ScriptsPath "downloaded_configs"

    New-Item -Path $SavePath -ItemType Directory -Force -ErrorAction Ignore | Out-Null 


    ForEach($cfg in $Links){


        $CityName = $cfg.Name
        $Id = $cfg.ClusterId
        $StrLink ="/custom_installer?cluster_id={0}&os={2}&source={3}" -f $Id, $Code, $Os, $Source

        $FilePath = Join-Path $SavePath $cfg.File
        $FilePath = $FilePath + '.ovpn'
        Write-host "Downloading VPN Config $CityName,  cluster id $Id to `"$FilePath`"" -f DarkCyan
        $Url = "https://www.expressvpn.com"
        Invoke-WebRequest -UseBasicParsing -Uri $Url -WebSession $session -Headers $headerz -OutFile "$FilePath"
    }

    

}
    

try{
    [System.Collections.ArrayList]$AllVpnconfig = [System.Collections.ArrayList]::new()
    Write-Host "Extracting Configuration Links..."
    1..5 | % {
        $Id = $_
        $NumLinks = $AllVpnconfig.Count
        Write-Host "Get Links for Continent $Id`: " -NoNewLine
        $TmpList = Invoke-ExtractVpnConfigFileLinks $Id
        ForEach($item in $TmpList){
            [void]$AllVpnconfig.Add($item)
        }
        $NewNumLinks = $AllVpnconfig.Count
        $NumExtracted = $NewNumLinks - $NumLinks
        Write-Host "Extracted $NumExtracted links."
    }
}catch{
    Write-Error "$_"
}

Save-VpnConfigurationFiles