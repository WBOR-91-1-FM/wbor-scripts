# wbor-spinitron-scripts

## validate_new

Checks a list of spins' release year against the year it was spun during, returning spin objects whose spin year doesn't match the song's release year.

Run with `python3 validate_new.py`. Expects `input.csv` in the same directory as the script.

### `input.csv`

[Generate a report](https://spinitron.com/m/spin/chart) on Spinitron's site. For this script, I like to filter by "New Release: Yes" and then expand to the past few years. Choose "Export/email" and select the following fields:

Required:

* `Date`
* `Released`

Not required but useless without:

* `Artist`
* `Song`
* `Release` (album)

Download as `.csv` and save to the script's folder.
