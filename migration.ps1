Get-ChildItem -Directory `
  | Foreach-Object { 
    $url=$(git -C $_ remote get-url origin 2> $null) 
    if($url -like "*github*habitus*health*") { 
      $url -replace ".*github.com.*?habitus-health/","git@bitbucket.org:habitus-health/"
    }
  }
