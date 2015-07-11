# DateTime Utility

for MT 6+.

## mt:EntryUnpublishingDate

Output entry unpublished_on.

## unit_timestamp

    <mt:EntryDate format="%Y%m%d%H%M%S" unit_timestamp="1">

To compare with time() in PHP.

## AllowPastUnpublishedOn

Allows user to set past unpublished date. If the unpublished date is past date, draft the entry or the page instead of an error.

    # mt-config.cgi
    AllowPastUnpublishedOn 1
