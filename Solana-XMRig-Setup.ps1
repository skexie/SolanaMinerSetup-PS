﻿# Author: skexie
# Date: 4/26/23
# About: I designed this script pull latest version of xmrig and begin mining SOL, directly to your Helium wallet!
#
#
# There is a referral code appended to the end of the URL generated by this script that will thank me for my time creating this. 
# Using this code, also reduces your transaction fee from unmineable by 25%!
#
# If you would prefer to send thanks another way, please feel free to buy me a coffee 
# 
# https://buymeacoffee.com/skexie
# 
$ref = "dhv1-cm07" #this is my referral address (skexie)
cls

$script:down_dir = Get-Location


Write-Host "You are about to download XMRig to '" -NoNewline
Write-Host "$($down_dir)" -NoNewline -ForegroundColor Yellow
Write-Host "' and begin mining SOL!!!!"

function begin{
    Write-Host ""
    Write-Host ""
    Write-Host "To continue, please enter " -NoNewline
    write-host "[y]" -ForegroundColor Green -NoNewline
    Write-Host "es. If you would would like to move to a different folder, please select " -NoNewline
    Write-Host "[c]" -ForegroundColor Yellow -NoNewline
    Write-Host "hange."
}

function Get-The-Address{
    $filename = "wallet_addr.txt"
    
    if(Test-Path "$($thepath)\$filename"){
    Write-Host "Config file found. Reading contents" -foregroundcolor Green
        $addr = Get-Content "$($thepath)\$($filename)"
        if($addr.Length -lt 32){
            Write-Host "Invalid address length in config file."
            Rename-Item "$($thepath)\$($filename)" -NewName "$($thepath)\$($filename)_old"
            Get-The-Address
        }
    }else{
        do{
            $addr = Read-Host "Enter wallet address to continue"
        }until($addr -ne $null)
        
        $addr | out-file "$($thepath)\$filename"
    }

    return $addr

}

function Get-XM{
    $repo = "xmrig/xmrig"
    $uri = "https://api.github.com/repos/$($repo)/releases"

    #force TLS
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $script:ver = (Invoke-WebRequest $uri | ConvertFrom-Json)[0].tag_name
    $script:ver = $ver.Replace("v", "")
    $filename = "xm_download-$($ver).zip"

    $uri = "https://github.com/$($repo)/releases/latest/download/xmrig-$($ver)-gcc-win64.zip" 
    Invoke-WebRequest -Uri $uri -OutFile "$($thepath)\$($filename)"
    
    return $filename
}


do{
    begin
    $in = Read-Host 
}until(($in.ToLower() -eq "y") -or ($in.ToLower() -eq "c"))

$lower_in = $in.ToLower()

if($lower_in -eq "y"){
    #continue with current directory
    $thepath = Get-Location
    
}elseif($lower_in -eq "c"){
    #user will need to provide a new directory

    $newpath = Read-Host -Prompt "Enter path or press Enter to browse"
    if($newpath -eq ""){
        Add-Type -AssemblyName System.Windows.Forms
        $FBrowser = New-Object System.Windows.Forms.FolderBrowserDialog 
        $FBrowser.ShowNewFolderButton = $true
        $null = $FBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true; TopLevel = $true }))
        $thepath = $FBrowser.SelectedPath
        Write-Host $thepath
        
    }else{
        $thepath = $newpath
    } 
}else{
    Write-Host "Unexpected input. Please try again and select either " -NoNewline
    Write-Host "y" -ForegroundColor Green -NoNewline
    Write-Host " or " -NoNewline
    Write-Host "c" -ForegroundColor Yellow -NoNewline
    Write-Host " . Exiting program"
    break
}
try{
    Set-Location $thepath -ErrorAction stop
}catch{
    write-host "The path entered was not found. Please try again." -ForegroundColor Red 
    pause
    break
}

$addr = Get-The-Address

if(Test-Path "$($thepath)\xmrig.exe" ){
    cls
    do{
        Write-Host "XMRig is already in the target folder."
        Write-Host "Hit Enter to continue with the current XMRig instance or " -NoNewline
        Write-Host "[d]" -ForegroundColor Yellow -NoNewline
        Write-Host " to download the latest copy from GitHub"
        $response = Read-Host
    }until(($response.ToLower() -eq "d") -or ($response -eq ""))
}else{
    Write-Host "XMRig not found" -ForegroundColor Red
    $dl_file = Get-XM
    Expand-Archive "$($thepath)\$($dl_file)" -DestinationPath "$($thepath)" -Force
    $thepath = (Get-ChildItem -Path $thepath -Directory).FullName
}

if($response.ToLower() -eq "d"){
    $dl_file = Get-XM
    Expand-Archive $dl_file -DestinationPath "$($thepath)" -Force
    $thepath = (Get-ChildItem -Path $thepath -Directory).FullName
    Start-Process -FilePath "$($thepath)\xmrig\xmrig-$($ver)\xmrig.exe" -ArgumentList "-o stratum+ssl://rx-us.unmineable.com:443 -a rx -k -u SOL:$($addr)#$($ref) -p x"
}else{
    Start-Process -FilePath "$($thepath)\xmrig.exe" -ArgumentList "-o stratum+ssl://rx-us.unmineable.com:443 -a rx -k -u SOL:$($addr)#$($ref) -p x" -Wait
}

