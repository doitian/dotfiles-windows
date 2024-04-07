ps | ? { $_.product -like "*gnupg*" } | stop-process
