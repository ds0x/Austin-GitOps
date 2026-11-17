# Configures Cloudflare WARP (Cloudflare One) on Windows after Fleet installs it.
# Placeholder for now: it only prints an ASCII animal. Real configuration
# (for example writing C:\ProgramData\Cloudflare\mdm.xml with your team
# name) will replace the body below.

$owl = @'
   ,___,
   (O,O)    WARP installed!
   /)  )    Configuration coming soon.
  --"--"--
'@

Write-Output $owl
exit 0
