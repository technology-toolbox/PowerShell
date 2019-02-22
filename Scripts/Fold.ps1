#----------------------------------------------------------------
# Fold.ps1
#----------------------------------------------------------------
param
(
  [string]$filespec = $null,
  [bool]$spaces = $false,
  [int]$width = 80
);

#----------------------------------------------------------------
# function Is-SpaceChar
#----------------------------------------------------------------
function Is-SpaceChar()
{
  param([char]$c);
  $isSpace = ([string]$c).Trim().Length -eq 0;
  $isSpace;
}

#----------------------------------------------------------------
# function Do-Fold
#----------------------------------------------------------------
function Do-Fold()
{
  param
  (
    [string]$filespec = $null,
    [bool]$spaces = $false,
    [int]$width = 80
  );

  $files = @(Get-ChildItem $filespec -ErrorAction SilentlyContinue);
  if ( $null -ne $files )
  {
    foreach ($file in $files)
    {
      $content = @(Get-Content $file);
      if ( $content )
      {
        foreach ($line in $content)
        {
          # if line is greater than width, chunk it up
          while ($line.Length -ge $width)
          {
            $widthtouse = $width;
            if ( $spaces )
            {
              if ( Is-SpaceChar $line[$width-1] )
              {
                # current break point is a space so use it.
              }
              elseif ( !(Is-SpaceChar $line[$width]) )
              {
                # current char is not a space and neither
                # is the next one so we'll need to roll
                # back until we find a space.
                for($j=$width; $j -gt 0; $j--)
                {
                  if ( Is-SpaceChar $line[$j] )
                  {
                    $widthtouse = $j;
                    break;
                  }
                }
              }
            }
            
            $subline = $line.SubString(0, $widthtouse);
            $subline;
            $line = $line.SubString($widthtouse);
          }
          
          # output the remainder of the line
          $line;
        }
      }
    }
  }
  else
  {
    "No files matching pattern '$filespec' found!";
  }
}

Do-Fold -filespec $filespec -spaces $spaces -width $width;
