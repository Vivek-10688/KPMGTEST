$jsonobjects = @"
{
"NestedObjects":
    [
        {
            "Name": "a",
            "Type": "value of a"
        },

        {
            "Name": "b",
            "Type": "value of b"
        },

        {
            "Name": "c",
            "Type": "value of c"
        },

        {
            "Name": "d",
            "Type": "value of d"
        }
    ]
}
"@

$convertedjsonobjects = $jsonobjects | ConvertFrom-Json

# way 1 to access the nested objects
$convertedjsonobjects.NestedObjects[0]
$convertedjsonobjects.NestedObjects[1]

# way 2 to access the nested objects
$a = $convertedjsonobjects.NestedObjects | Where-Object { $_.Name -eq "a" }
Write-Output $a | Out-Default