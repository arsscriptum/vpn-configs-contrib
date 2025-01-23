
function Get-VpnLoginLandingPage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, Position=0)]
        [String]$Username,
        [Parameter(Mandatory=$True, Position=1)]
        [String]$Password
    )
    try{
      $Headerz = @{
        "authority"="www.expressvpn.com"
        "method"="POST"
        "path"="/sessions"
        "scheme"="https"
        "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
        "referer"="https://www.expressvpn.com/sign-in"
      } 
      $BodyString = "utf8=%E2%9C%93&xkgztqpe=eIwjm%2B90tni0UwTGC9H7LmTOp0ZfkfoCzDDY8RdzuDrefniraQ9L7hZAII3a2%2BKpIcrcNc%2BbXVcfpxf7C%2B19dA%3D%3D&location_fragment=&6dd41b0f=&redirect_path=&email={0}&password={1}&commit=Sign+In" -f [System.Net.WebUtility]::UrlEncode($Username), [System.Net.WebUtility]::UrlEncode($Password)

      $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
      $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
      $session.Cookies.Add((New-Object System.Net.Cookie("_xv_web_frontend_session", "SHVNL1prcDB5YjVTK29tSkMyWEhvaks3M3N2cWhRL3JWdGVaSjFyZVRSSHE0WUp1S01ZZUQ2ZXRCU2ZKSnVXVHBzT1Rtb1BTVEtDZFRaNzZBVUYzdFRRM3o0K0xpZ2FaUW5mUWpWdER5OC9ranJiR3RpWTI0eG1GV0tiVHA5NGhhaXh0Z1VXUE9zY2NiME5Rekh0d2MrcS8wcDFpZ1gvZE94SW9LWUNrQWtDamtkU1l5ZVdDY0lwZ0xkOUVqcFZ5bExJRnRsd1R5ZVFGaUMrbmNzb1B2cWlSRDhxV0Faa0tFT1N1OUhNT3p6eElpRHhDMHRkSXhRQ1BQNSt6Zm0xRUx0b3p3bmo5MzNIbkloaks5YW5qbkxLUGprSVc1bExabjdWWXZXenRyRDB1M05IL3kvSkkzTUcxMkJGbGx2Z25ncm5SNFJUWXZ5R3NhREp6WmdqeUN3PT0tLURRS2FCaVFHZ2FpUnlwMlR2OEwzNkE9PQ%3D%3D--ff089b5f0227442b59f38b0c343253388ba8e0e1", "/", "www.expressvpn.com")))
      
      $Url = "https://www.expressvpn.com/subscribe"
      $Request1 = Invoke-WebRequest -UseBasicParsing -Uri $Url -Method "POST" -WebSession $session -Headers $Headerz -ContentType "application/x-www-form-urlencoded" -Body $BodyString

      $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
      $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
      $session.Cookies.Add((New-Object System.Net.Cookie("_xv_web_frontend_session", "YWpWenE0aUtzckpKZDB5ZWtBeStCaTd4QjZORkRWeVI3T2ZsWDVvM0VFdVA1SFNqN0FsM1R2SjhXUDZ3SEF6VFlSN2ZrM3ZLcVBBK2hWdjdjSEFlNkNFZUgzTDkxWVNEclpXQSt1MVBHbmF3V2Q5VzcySEQyY2JuZUZpUFJ3T1IrbkxweStDa3ZweDRGVlNQOGdyVVZVUlc2dzVQSnRuNzFCN3BmbG9FZUt4akx6TkN6bEZsN3hSMkZDZkZBNVBCOGV4cllBQVVLSkRrN3dQV1MreGJSbnNteGJtdlNmckRyQkJrc0hiTHEydDdRUjVnZjNZNzJRenBwVkZGd2pnUGpjUkNkNU5qWDR5YVJUY2p5UjFwNXg2N3hvai9jOE5jMDF2S1ozYmtUWnR2eWFvSzZSK0doeC9jKzVBZldtWklZcmh3N1dBc3NvWWV0VHQ5dGFFWk5TSmQxRnQ2Yi9VM2FpT1lUbVZPRzBTVFBBbmVpYldoMG1GN0UzT0dPaUNqbU9LMFRhWUNNUExNVnNnNE5IdHVJM0JreXRrajhhUitHTEJ2SHJ5cS81VzIvcmlkVTV5azBIL25MOVVVSFkvOUZXeS9VVHZOVzRqb0c0WFZsUFVveGhESXg4eFlPVjZ5eTRlemh4OHBENjVhSlMvRWxBUEFwdk5xcGRiaXZ1NGs0SFFSZlo1Q1ljeE8wNVE2UXAxT1FzWGx2LzA4Mm4wdm4wK2E3UHBmWSt4MEs3NFZqRTdQaVRJcDB4UnoyaHd0RzdoU3UxWGVtK3lLdXcrSGJ4dXpwNXNUcjFrUEgxVDBNb01HZll3N0xiL0wyUlNmZnJHTTJyelhwKytXd0pNbUVTZ0ljTmVlVXFRQkN3cDlKSUNUNWpMUWdBcUt4dHNtK0hXamh0Ym1nMDdRL3oydGU5eVZkT2hNdE4xTGhhRVovUlZMUFVUeWdQQXpsUlo3SUdvMkJjWnFLbGpjeEVwM05IUDk5SFdQOGd0VEdDd2VWcFIzUXlHVUZTTHB1eTNRYitGaUZmVjVQbWdXMHdxQ3ZGYWluUG5DWkVqRys3NnVYWkplRUZEWCtldVNIQkRoK0xYRDZTa24zMmt1aHZkQlA4MFB2V2xJa3lhcFJxQXhKTXM0MjdLVUkyNVg3OGNwczA1MVcvQldnNXUxcmo3UDdGcGFsYnp4eG1yUDZkR0JZOVVKeDNhV2xZTFVsS00xL3NETVhwbWluMFJERlNGdVBSeEF2aUZQWFFzRy95dWszeDl2MDdzRjJsSUZ2a3hnLS1jK3MzRlBMaHBhaXhYbnkrWng5YlJBPT0%3D--b564033da9cfbe080e06b4a842efb68bc674c648", "/", "www.expressvpn.com")))
      
      $Url = "https://www.expressvpn.com/setup#manual"
      $Request2 = Invoke-WebRequest -UseBasicParsing -Uri $Url -Method "POST" -WebSession $session -Headers $Headerz -ContentType "application/x-www-form-urlencoded"

      if($Request2.StatusCode -eq 200){
         $FileContent = $Request2.Content 
         return $FileContent 
      }
      $Null

    }catch{
      write-error $_
    }
}
