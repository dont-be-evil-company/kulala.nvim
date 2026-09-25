# FROM mcr.microsoft.com/windows/nanoserver:20H2-amd64
FROM mcr.microsoft.com/powershell:lts-windowsservercore-1809

SHELL ["pwsh", "-Command"]

USER ContainerAdministrator

WORKDIR "C:\\kulala.nvim"

RUN Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
RUN Invoke-RestMethod -Uri https://get.scoop.sh -outfile 'install.ps1'
RUN .\install.ps1 -RunAsAdmin

# required before add extras
RUN scoop install main/git

# add for extras suggested by neovim
RUN scoop bucket add extras

RUN scoop install extras/vcredist2022
RUN scoop install main/neovim@0.10.2

WORKDIR "C:\\luajjt"

RUN Invoke-RestMethod -Uri https://github.com/dont-be-evil-company/luajit-for-win64/archive/refs/tags/v0.0.2.zip -outfile luajit.zip
RUN 7z x luajit.zip

WORKDIR "C:\\luajjt\luajit-for-win64-0.0.2"

RUN .\luajit-for-win64.cmd

RUN setx /M KULALA_LUA_DIR \"C:\luajjt\luajit-for-win64-0.0.2\"

RUN setx /M PATH \"$Env:KULALA_LUA_DIR\tools\cmd;$Env:KULALA_LUA_DIR\tools\PortableGit\mingw64\bin;$Env:KULALA_LUA_DIR\tools\PortableGit\usr\bin;$Env:KULALA_LUA_DIR\tools\mingw\bin;$Env:KULALA_LUA_DIR\lib;$Env:KULALA_LUA_DIR\bin;$Env:APPDATA\LJ4W\LuaRocks\bin;$Env:path\"

RUN setx /M LUA_PATH \"$Env:KULALA_LUA_DIR\lua\?.lua;$Env:KULALA_LUA_DIR\lua\?\init.lua;$Env:APPDATA\luarocks\share\lua\5.1\?.lua;$Env:APPDATA\luarocks\share\lua\5.1\?\init.lua;$Env:LUA_PATH\"
RUN setx /M LUA_CPATH \"$Env:APPDATA\luarocks;$Env:APPDATA\luarocks\lib\lua\5.1\?.dll;$Env:LUA_CPATH\"

RUN luarocks install --lua-version 5.1 busted

WORKDIR "C:\\kulala.nvim"

RUN git config --global safe.directory '*'
RUN git config --global core.autocrlf true

ENTRYPOINT ["pwsh"]
