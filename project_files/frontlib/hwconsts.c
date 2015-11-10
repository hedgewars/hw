/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "hwconsts.h"

const uint32_t flib_teamcolors[] = HW_TEAMCOLOR_ARRAY;
const size_t flib_teamcolor_count = sizeof(flib_teamcolors)/sizeof(uint32_t)-1;

static const flib_metascheme_setting metaSchemeSettings[] = {
    { .name = "damagefactor",      .times1000 = false, .engineCommand = "e$damagepct",   .maxMeansInfinity = false, .min = 10, .max = 300,  .def = 100 },
    { .name = "turntime",          .times1000 = true,  .engineCommand = "e$turntime",    .maxMeansInfinity = true,  .min = 1,  .max = 9999, .def = 45  },
    { .name = "health",            .times1000 = false, .engineCommand = NULL,            .maxMeansInfinity = false, .min = 50, .max = 200,  .def = 100 },
    { .name = "suddendeath",       .times1000 = false, .engineCommand = "e$sd_turns",    .maxMeansInfinity = true,  .min = 0,  .max = 50,   .def = 15  },
    { .name = "caseprobability",   .times1000 = false, .engineCommand = "e$casefreq",    .maxMeansInfinity = false, .min = 0,  .max = 9,    .def = 5   },
    { .name = "minestime",         .times1000 = true,  .engineCommand = "e$minestime",   .maxMeansInfinity = false, .min = -1, .max = 5,    .def = 3   },
    { .name = "minesnum",          .times1000 = false, .engineCommand = "e$minesnum",    .maxMeansInfinity = false, .min = 0,  .max = 80,   .def = 4   },
    { .name = "minedudpct",        .times1000 = false, .engineCommand = "e$minedudpct",  .maxMeansInfinity = false, .min = 0,  .max = 100,  .def = 0   },
    { .name = "explosives",        .times1000 = false, .engineCommand = "e$explosives",  .maxMeansInfinity = false, .min = 0,  .max = 40,   .def = 2   },
    { .name = "healthprobability", .times1000 = false, .engineCommand = "e$healthprob",  .maxMeansInfinity = false, .min = 0,  .max = 100,  .def = 35  },
    { .name = "healthcaseamount",  .times1000 = false, .engineCommand = "e$hcaseamount", .maxMeansInfinity = false, .min = 0,  .max = 200,  .def = 25  },
    { .name = "waterrise",         .times1000 = false, .engineCommand = "e$waterrise",   .maxMeansInfinity = false, .min = 0,  .max = 100,  .def = 47  },
    { .name = "healthdecrease",    .times1000 = false, .engineCommand = "e$healthdec",   .maxMeansInfinity = false, .min = 0,  .max = 100,  .def = 5   },
    { .name = "ropepct",           .times1000 = false, .engineCommand = "e$ropepct",     .maxMeansInfinity = false, .min = 25, .max = 999,  .def = 100 },
    { .name = "getawaytime",       .times1000 = false, .engineCommand = "e$getawaytime", .maxMeansInfinity = false, .min = 0,  .max = 999,  .def = 100 }
};

static const flib_metascheme_mod metaSchemeMods[] = {
    { .name = "fortsmode",          .bitmaskIndex = 12 },
    { .name = "divteams",           .bitmaskIndex = 4  },
    { .name = "solidland",          .bitmaskIndex = 2  },
    { .name = "border",             .bitmaskIndex = 3  },
    { .name = "lowgrav",            .bitmaskIndex = 5  },
    { .name = "laser",              .bitmaskIndex = 6  },
    { .name = "invulnerability",    .bitmaskIndex = 7  },
    { .name = "resethealth",        .bitmaskIndex = 8  },
    { .name = "vampiric",           .bitmaskIndex = 9  },
    { .name = "karma",              .bitmaskIndex = 10 },
    { .name = "artillery",          .bitmaskIndex = 11 },
    { .name = "randomorder",        .bitmaskIndex = 13 },
    { .name = "king",               .bitmaskIndex = 14 },
    { .name = "placehog",           .bitmaskIndex = 15 },
    { .name = "sharedammo",         .bitmaskIndex = 16 },
    { .name = "disablegirders",     .bitmaskIndex = 17 },
    { .name = "disablelandobjects", .bitmaskIndex = 18 },
    { .name = "aisurvival",         .bitmaskIndex = 19 },
    { .name = "infattack",          .bitmaskIndex = 20 },
    { .name = "resetweps",          .bitmaskIndex = 21 },
    { .name = "perhogammo",         .bitmaskIndex = 22 },
    { .name = "disablewind",        .bitmaskIndex = 23 },
    { .name = "morewind",           .bitmaskIndex = 24 },
    { .name = "tagteam",            .bitmaskIndex = 25 },
    { .name = "bottomborder",       .bitmaskIndex = 26 }
};

const flib_metascheme flib_meta = {
    .settingCount = sizeof(metaSchemeSettings)/sizeof(flib_metascheme_setting),
    .modCount = sizeof(metaSchemeMods)/sizeof(flib_metascheme_mod),
    .settings = metaSchemeSettings,
    .mods = metaSchemeMods
};

uint32_t flib_get_teamcolor(int colorIndex) {
    if(colorIndex>=0 && colorIndex < flib_teamcolor_count) {
        return flib_teamcolors[colorIndex];
    } else {
        return 0;
    }
}

int flib_get_teamcolor_count() {
    return flib_teamcolor_count;
}

int flib_get_hedgehogs_per_team() {
    return HEDGEHOGS_PER_TEAM;
}

int flib_get_weapons_count() {
    return WEAPONS_COUNT;
}

const flib_metascheme *flib_get_metascheme() {
    return &flib_meta;
}
