# Hedgewars random name lists
The directory Data/Names contains random hog and team names and
hat sets for themed teams.

In this file I'll explain the format of each of the files:

## `<Hat>.cfg`
Hat configuration file.
This file lists the random name list (without file name suffix), e.g.:

    generic
    nordic

and so on. Each list name must exist in this directory. When choosing
a random name for this hat, it will first randomly choose one of the
name lists, then choose a random name within that list.

`<Hat>` must be the name of a hat (without file name suffix) for which
to apply the random names, e.g. “Santa”.

If a hat does not have a config file, it will use the generic name list.

## `<name>.txt` =
This is a list of random hedgehog names, one name per line.
`<name>` is an identifier of your choice (except “types”).

## `generic.txt` ==
Works exactly like `<name>.txt`, but this file is also used as default for all
hats without a .cfg file.

This file must be present at all costs!

## `types.txt` =
This contains themed team names and hat sets.
It works like this:

For each team:

* First comes a list of possible team names for a team type.
* Then comes a separator line with 5 equals signs (“=====”).
* Then comes a list of hat names with out file name suffix.
* Each hog of this team gets a random hat of this list. Repeat a hat name to
  jack up its probability.

Each team is again separated by a separator line.

At the end of the final team, this line must be written (without the spaces):

    *END*

Everything after that will be ignored.

This file must be present at all costs!
