$LogStart = $Args[1]
# Recursively iterate over each file in the target folder, and attempt to upload any .evtc files contained in it. 
# As long as the log file comes after the start time. 
function GetFiles($path = $pwd, [string[]]$exclude) 
{ 
    foreach ($item in Get-ChildItem $path)
    {
        if ($exclude | Where {$item -like $_}) { continue }

        if (Test-Path $item.FullName -PathType Container) 
        {
            GetFiles $item.FullName $exclude
        } 
        else 
        { 
            if( $item -like "*.evtc" -AND $item.lastwritetime -gt $LogStart) {
                TRY {
                    .\ParseJSON.ps1 $item.FullName
                }
                CATCH {
                    # echo $_.Exception.Message >> $LogScriptError
                    echo $_.Exception.Message
                    # echo $_.Exception.ItemName >> $LogScriptError
                    echo $_.Exception.ItemName
                }
            }
        }
    } 
}

# Double Check the strike missions. 
GetFiles $Args[0]