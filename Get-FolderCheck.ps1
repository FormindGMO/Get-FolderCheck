<#
  .SYNOPSIS
  Check Folder integrity recursibely

  .PARAMETER Folder1
  First Folder to check against
  
  .PARAMETER Folder2
  Second Folder to check against
  
  .PARAMETER ContinueOnDifference
  If Difference was found, keep checking for other differences

  .INPUTS
  None. You cannot pipe objects to Update-Sentinel-Tenant.ps1.

  .NOTES
    Version:        1.0
    Author:         Geoffrey Montel <geoffrey.montel@formind.fr>
    Creation Date:  17/05/2021

  .EXAMPLE
  PS> .\Get-FolderCheck.ps1 candidate/ C:\copy
#>

[CmdletBinding()]
param (
  [parameter(Mandatory = $true)]
  [ValidateScript({
      if ( -Not ($_ | Test-Path -PathType Container) ) {
        throw "Folder $_ does not exist"
      }
      return $true
    })] [System.IO.FileInfo] $folder1,
  [parameter(Mandatory = $true)]
  [ValidateScript({
      if ( -Not ($_ | Test-Path -PathType Container) ) {
        throw "Folder $_ does not exist"
      }
      return $true
    })]
  [System.IO.FileInfo] $folder2,
  [switch] $ContinueOnDifference = $false
)
begin {
  $ErrorActionPreference = "Stop"
  [bool] $differentRepos = $false
  [int] $iter = 0
  [string] $algorithm = "MD5"
}
process {

  Push-Location $folder1
  Write-Debug "Enumerating # of files in $folder1"
  $file1Set = Get-ChildItem -Recurse -File
  $file1SetCount = $file1Set.Count
  Write-Debug "$file1SetCount files in lest repository."

  Write-Debug "First check if the files are present everywhere"
  $file2Set = Get-ChildItem -Recurse -File -Path $folder2

  ##################
  # STEP 1 : BUILT-IN APPROACH
  ##################
  $diffList = Compare-Object -ReferenceObject $file1Set -DifferenceObject $file2Set
  if ($diffList) {
    Write-Warning "Repos are different in List of files: "
    Write-Warning $($diffList | Format-Table)
    if (!$ContinueOnDifference) { return $false }
  }
  Write-Debug "Step Builtin finished, getting to Hash Step"

  ##################
  # STEP 2  HASH APPROACH
  ##################
  foreach ($file1 in $file1Set) {
    $iter++
    $relPath = Resolve-Path -Relative $file1

    Write-Progress -Activity "Iterating through files" `
      -CurrentOperation $relPath `
      -PercentComplete ($iter / $file1SetCount)

    $file2 = $(Join-Path $folder2 $relPath)
    if (Test-Path -PathType leaf -Path $file2) {
      $hash1 = (Get-FileHash -Path $file1 -Algorithm $algorithm).Hash
      $hash2 = (Get-FileHash -Path $file2 -Algorithm $algorithm).Hash

      if ($hash1 -eq $hash2) {
        Write-Debug "[OK] $relPath ($algorithm : $($hash1.Substring(0,5))...)"
      }
      else {
        Write-Warning "$relPath mismatch for the two folders (Left: $($hash1), Right: $($hash2))"
        $differentRepos = $true
        if (!$ContinueOnDifference) { break; }
      }
    }
  }

  Pop-Location

  if ($differentRepos) {
    Write-Output "The two folders are different"
    Write-Debug "($folder1 // $folder2)"
  }
  return !($differentRepos)
}
