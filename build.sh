#!/bin/bash
# What will this script do:
# 1. run CGO-CPython Tool to determine PKG_CONFIG_PATH and cgo directives
# 2. set cgo directives to voidruntime/plugin.go by a python script
# 3. clean go build cache
# 4. build
echo
echo voidshell Build Tool \(1.0 20R14a\)
echo
echo running cgo-cpython-tool for voidshell plugin support...
source ./cgo-cpython-tool.sh
if [ $? != 0 ]; then
    echo Error: build failed: checking for python3 development environment failed.
    exit 1
fi
echo Python-Dev installed List:
pkg-config --list-all | grep --color=never python 
echo
echo \* modify plugin.go cgo directives... \(in tag _VOID_RUNTIME_PLUGIN_GO_CGO_AUTOFILL_\)...
python3 - "$@" <<END
#!/usr/bin/python3
import re,os
f=open("voruntime/plugin.go","r")
plugin_src=f.read()
f.close()
pat="//BEGIN _VOID_RUNTIME_PLUGIN_GO_CGO_AUTOFILL_\n"+".*?"+                     "\n"+"//END _VOID_RUNTIME_PLUGIN_GO_CGO_AUTOFILL_"
rep="//BEGIN _VOID_RUNTIME_PLUGIN_GO_CGO_AUTOFILL_\n"+os.environ["VO_BUILD_CGO"]+"\n"+"//END _VOID_RUNTIME_PLUGIN_GO_CGO_AUTOFILL_"
if re.search(pat,plugin_src)==None:
    print("cannot find tag _VOID_RUNTIME_PLUGIN_GO_CGO_AUTOFILL_ wrapped segment in plugin.go")
    exit(1)
auto_src=re.sub(pat,rep,plugin_src)
f=open("voruntime/plugin.go","w")
f.write(auto_src)
f.close()
END
if [ $? != 0 ]; then
    echo
    echo Error: build failed: cannot overwrite CGO directives in voruntime/plugin.go
    exit 1
fi
echo \* go build...
go clean
go build
if [ $? != 0 ];then
    echo
    echo Error: build failed
    exit 1
else
    echo
    echo "build succeed.🍺"
fi