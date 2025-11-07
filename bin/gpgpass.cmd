for /f "delims=" %%i in ('git config user.email') do set email=%%i
gopass show -c "ids/ian/gpg/%email%"
