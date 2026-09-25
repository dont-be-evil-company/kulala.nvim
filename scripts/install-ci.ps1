$Env:KULALA_ROOT_DIR = (Get-Location).Path

if ($Env:GH_CACHE_HIT -eq $null) {
  mkdir .tests
}

cd .tests

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

if ($Env:GH_CACHE_HIT -eq $null) {
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  scoop install main/git
  scoop install main/neovim@0.12.2
} else {
  $Env:PATH = "$Env:USERPROFILE\scoop\shims;$Env:USERPROFILE\scoop\apps\git\current\cmd;$Env:USERPROFILE\scoop\apps\neovim\current\bin;$Env:PATH"
}

if ($Env:GH_CACHE_HIT -eq $null) {
  Invoke-RestMethod -Uri https://github.com/dont-be-evil-company/luajit-for-win64/archive/refs/tags/v0.0.2.zip -outfile luajit.zip
  7z x luajit.zip
  RM luajit.zip
  cd luajit-for-win64-0.0.2
  .\luajit-for-win64.cmd
} else {
  cd luajit-for-win64-0.0.2
}

$Env:KULALA_LUA_DIR = (Get-Location).Path

$Env:PATH = "$Env:KULALA_LUA_DIR\tools\cmd;$Env:KULALA_LUA_DIR\tools\PortableGit\mingw64\bin;$Env:KULALA_LUA_DIR\tools\PortableGit\usr\bin;$Env:KULALA_LUA_DIR\tools\mingw\bin;$Env:KULALA_LUA_DIR\lib;$Env:KULALA_LUA_DIR\bin;$Env:APPDATA\LJ4W\LuaRocks\bin;C:\Program Files\nodejs;$Env:PATH"
$Env:LUA_PATH = "$Env:KULALA_LUA_DIR\lua\?.lua;$Env:KULALA_LUA_DIR\lua\?\init.lua;$Env:APPDATA\luarocks\share\lua\5.1\?.lua;$Env:APPDATA\luarocks\share\lua\5.1\?\init.lua;$Env:LUA_PATH"
$Env:LUA_CPATH = "$Env:APPDATA\luarocks;$Env:APPDATA\luarocks\lib\lua\5.1\?.dll;$Env:LUA_CPATH"

if ($Env:GH_CACHE_HIT -eq $null) {
  luarocks install --lua-version 5.1 busted
}

# Persist the Environment Variables
"PATH=$Env:Path" >> $Env:GITHUB_ENV
"LUA_PATH=$Env:LUA_PATH" >> $Env:GITHUB_ENV
"LUA_CPATH=$Env:LUA_CPATH" >> $Env:GITHUB_ENV

cd $Env:KULALA_ROOT_DIR
