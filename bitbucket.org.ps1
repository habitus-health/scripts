Function Say ($Color, $Message, $Delay = 100) {
  Write-Host -F  $Color  $Message
  Start-Sleep -Milliseconds $Delay
}
Function Get-Repositories {
  return Get-ChildItem -Directory -Recurse -Depth 2 | Where-Object {
    Test-Path $(Join-Path $_ ".git")
  }
}

Say Cyan "bitbucket.org migration script" 3000
Say Yellow "There are a few steps we need to do in order to get this done:"
Say DarkGray "|- 1. Point your local repositories to bitbucket.org"
Say DarkGray "|- 2. Generate a public and a private rsa key (ssh key)"
Say DarkGray "|- 3. Import the public key to your account"
Say DarkGray "|- 4. Test if the migration has succeeded" 3000
Say DarkGray "|- I'll generate the ssh-key for you but I'll need your help to import it to bitbucket account." 1000
Say Gray "|- Are your repositories located at this current directory ($(Get-Location))?"
Say Gray "|- press enter to continue ..."
Read-Host 

Remove-Item $HOME/.ssh -Force -Recurse 
New-Item -ItemType Directory ~/.ssh -Force | Out-Null
Add-Content ~/.ssh/known_hosts -Value "bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQeJzhupRu0u0cdegZIa8e86EG2qOCsIsD1Xw0xSeiPDlCr7kq97NLmMbpKTX6Esc30NuoqEEHCuc7yWtwp8dI76EEEB1VqY9QJq6vk+aySyboD5QF61I/1WeTwu+deCbgKMGbUijeXhtfbxSxm6JwGrXrhBdofTsbKRUsrN1WoNgUa8uqN1Vx6WAJw1JHPhglEGGHea6QICwJOAr/6mrui/oB7pkaWKHj3z7d1IC4KWLtY47elvjbaTlkN04Kc/5LFEirorGYVbt15kAUlqGM65pk6ZBxtaO3+30LVlORZkxOh+LKL/BvbZ/iRNhItLqNyieoQj/uh/7Iv4uyH/cV/0b4WDSd3DptigWq84lJubb9t/DnZlrJazxyDCulTmKdOR7vs9gMTo+uoIrPSb8ScTtvw65+odKAlBj59dhnVp9zd7QUojOpXlL62Aw56U4oO+FALuevvMjiWeavKhJqlR7i5n9srYcrNV7ttmDw7kf/97P5zauIhxcjX+xHv4M="
Add-Content ~/.ssh/known_hosts -Value "bitbucket.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPIQmuzMBuKdWeF4+a2sjSSpBK0iqitSQ+5BM9KhpexuGt20JpTVM7u5BDZngncgrqDMbWdxMWWOGtZ9UgbqgZE="
Add-Content ~/.ssh/known_hosts -Value "bitbucket.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIazEu89wgQZ4bqs3d63QSMzYVa0MuJ2e2gKTKqu+UUO"
Add-Content ~/.ssh/known_hosts -Value "|1|HuJ7owWgQaq+gd+Znk+jTZ26zZA=|VE8FdPjcU7NZqUoIfzIuuOMiACQ= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPIQmuzMBuKdWeF4+a2sjSSpBK0iqitSQ+5BM9KhpexuGt20JpTVM7u5BDZngncgrqDMbWdxMWWOGtZ9UgbqgZE="

Say Cyan "Looking for repositories to migrate ..."
$Repositories = Get-Repositories 

$Repositories | Foreach-Object {
  if (Test-Path $(Join-Path $_ ".git")) {
    $Origin = $(git -C $_ remote get-url origin 2> $null) 
    if ($Origin -like "*github*habitus*health*" -and $origin -notlike "mobile-app") {
      $NewOrigin = $Origin -replace ".*github.com.*?habitus-health/", "git@bitbucket.org:habitus-health/"
      git -C $_ remote set-url origin $NewOrigin
      Say DarkGray " |- $NewOrigin"
    }
  }
}

  if (!$Repositories) {
    Say Red "No repositories could be found at the current working directory"
    return
  }

  Say Yellow  "`n`nTime to create a new ssh-key..."
  Say DarkGray "`|- Generating the ssh private and public keys ..."
  ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa 
  Say DarkGreen "`|- The ssh key has just been copied to your clipboard, you'll need it later on!"
  Get-Content ~/.ssh/id_rsa.pub | Set-Clipboard

  Say Yellow "`nNow, we'll need to import the ssh-key to your bitbucket.org account."
  Say DarkGray "|- 1. I am going to opening your web browser at bitbucket.org and you may have to sign in. If so, use the [Microsoft] button"
  Say DarkGray "|- 2. When the browser opens on the page, click on the [Add key] button to create a new ssh-key"
  Say DarkGray "|- 3. Then you can paste the ssh public key that has already been copied to you clipboard"
  Say Gray "|- Are you ready?"
  Say Gray "|- press enter ..."
  Read-Host

  Say Yellow "Opening your web browser at https://bitbucket.org/account/settings/ssh-keys/"
  Start-Process https://bitbucket.org/account/settings/ssh-keys/
  Say DarkGreen "|- Remember that you already have the key copied on your clipboard"
  Say Gray "|- press enter to continue ..."
  Read-Host

  Say Yellow "Tests"
  $Repositories | ForEach-Object {
    Say DarkGray "$Origin "
    $Origin = $(git -C $_ remote get-url origin 2> $null) 
    $Output=$(git -C $_ fetch 2>&1)
    $HasErrors= $LASTEXITCODE -gt 0
    if(!$HasErrors){
      Say DarkGreen "|- ✅ $Origin " 0
    }else{
      Say DarkRed "|- ❌ $Origin " 0
      return $Output
    }
  }
