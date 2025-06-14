# ssh -R 31337:localhost:31337 host
# use `ncat localhost` in the remote host
while ($true) {
  $data = & ncat -l
  $data | Set-Clipboard
}
