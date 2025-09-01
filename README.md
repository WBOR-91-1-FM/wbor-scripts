# wbor-spinitron-scripts

## `automation-stream`

See folder `README`.

## `spinitron/validate_new.py`

Checks the release year for a list of Spinitron "spins" against the year it was played, returning spin objects whose spin year doesn't match the song's release year. In such case, the song may not be a "new release".

Run with `python3 validate_new.py`. Expects `input.csv` in the same directory as the script.

### `input.csv`

To use `validate_new.py`, you need a CSV export of your station's spins from Spinitron. You can
[generate a report](https://spinitron.com/m/spin/chart) on Spinitron's site. For this script, I filter by `'New Release: Yes'` and then expand to the past few years. Choose `'Export/email'` and select the following fields:

Required:

* `Date`
* `Released`

Not required but useless without:

* `Artist`
* `Song`
* `Release` (album)

Download as `.csv` and save to the script's folder.

## Log Rotation

All scripts log to `~/Logs/wbor/`. To prevent logs from growing indefinitely:

1. **Set up log rotation** (automatically rotates logs when they exceed 10MB, keeps 5 old versions):

   ```bash
   # Add to crontab
   crontab -e
   
   # Add this line to rotate logs daily at 2 AM
   0 2 * * * /Users/mdrxy/personal/wbor/wbor-scripts/lib/rotate-logs.sh >/dev/null 2>&1
   ```

2. **Manual rotation** (run as needed):

   ```bash
   ./lib/rotate-logs.sh
   ```
