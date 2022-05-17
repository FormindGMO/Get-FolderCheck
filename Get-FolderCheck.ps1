#requires -version 5
<#
  .SYNOPSIS
  Check Folder integrity recursibely

  .PARAMETER Folder1
  First Folder to check against
  
  .PARAMETER Folder2
  Second Folder to check against

  .INPUTS
  None. You cannot pipe objects to Update-Sentinel-Tenant.ps1.

  .NOTES
    Version:        1.0
    Author:         Geoffrey Montel <geoffrey.montel@formind.fr>
    Creation Date:  17/05/2021

  .EXAMPLE
  PS> .\Get-FolderCheck.ps1 candidate/ C:\copy
#>

[CmdletBinding(SupportsShouldProcess)]
[CmdletBinding()]
param (
    [parameter(Mandatory = $true)]
    [ValidateScript({
      if( -Not ($_ | Test-Path -PathType Container) ){
          throw "Folder $_ does not exist"
      }
      return $true
  })] [System.IO.FileInfo] $folder1,
    [parameter(Mandatory = $true)]
    [ValidateScript({
      if( -Not ($_ | Test-Path -PathType Container) ){
          throw "Folder $_ does not exist"
      }
      return $true
  })]
    [System.IO.FileInfo] $folder2,
    [switch] $BreakOnDifference = $false
)

process {
    $ErrorActionPreference = "Stop"
    [bool] $differentRepos = $false

    Push-Location $folder1
    #TODO : progress
    foreach ($file1 in Get-ChildItem -Recurse -File) {
      $relPath = Resolve-Path -Relative $file1
      $file2 = $(Join-Path $folder2 $relPath)
      if(Test-Path -PathType leaf -Path $file2){
        $hash1 = (Get-FileHash -Path $file1).Hash
        $hash2 = (Get-FileHash -Path $file2).Hash
        if ($hash1 -eq $hash2) {
          Write-Debug "Conformity OK for $relPath file. (hash: $($hash1.Hash))"
        }
        else{
          Write-Warning "$relPath mismatch for the two folders (Left: $($hash1.Hash), Right: $($hash2.Hash))"
          $differentRepos = $true
          if($BreakOnDifference){break;}
        }
      } else {
        Write-Warning "Can't find $file1 in right path $folder2."
        $differentRepos = $true
        if($BreakOnDifference){break;}
      }
    }

    Pop-Location

    if($differentRepos){
      Write-Output "The two folders are different"
      Write-Debug "($folder1 // $folder2)"
    }
    return !($differentRepos)
  }
