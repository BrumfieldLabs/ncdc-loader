PLACE_MAP = {
  "Maine" => "Q12",
  "New York" => "Q61",
  "Ohio" => "Q62",
  "United States" => "Q63",
  "New Hampshire" => "Q64",
  "Massachusetts" => "Q65",
  "Maryland" => "Q66",
  "New Jersey" => "Q67",
  "Kentucky" => "Q68",
  "Pennsylvania" => "Q69",
  "Washington, D.C." => "Q70",
  "Kentucky ?US" => "Q71",
  "Illinois " => "Q72",
  "Arizona" => "Q73",
  "England, United Kingdom" => "Q74",
  "Virginia" => "Q75",
  "Illinois" => "Q76",
  "Iowa" => "Q77",
  "Vermont" => "Q78",
  "Coahuila, Mexico" => "Q79",
  "Pacific Ocean" => "Q80",
  "West Virginia" => "Q81",
  "Tennessee" => "Q82",
  "Bavaria, Germany" => "Q83",
  "USA" => "Q84",
  "Rhode Island" => "Q85",
  "Atlantic Ocean" => "Q86",
  "Mississippi" => "Q87",
  "England" => "Q88",
  "Scotland" => "Q89"
}

FDP_QCODE = "Q5"
PAL_QCODE = "Q4"
KHS_QCODE = "Q6"

CSV_MAP = {
  "PUBLISHER" => {
    :pcode => 'P29',
    :value_map => {
      "FDP" => FDP_QCODE,
      "ALPLM" => PAL_QCODE,
      "ALPM" => PAL_QCODE,
      "KHS" => KHS_QCODE,
    }
  },
  "PUBLICATION" => {
    :pcode => 'P21',
   },
  "SERIES" => {
    :pcode => 'P17',
  },
  "VOLUME" => {
    :pcode => 'P14',
  },
  "BOOK" => {
    :pcode => 'P20',
  },
  "PAGE" => {
    :pcode => 'P16',
  },
  "NOTE" => {
    :pcode => 'P22',
  },
  "SURNAME" => {
    :pcode => 'P28',
  },
  "FORENAME" => {
    :pcode => 'P30',
  },
  "MIDDLE_NAME/INITIAL" => {
    :pcode => 'P30',
  },
  "ALTERNATE_NAME" => {
    :pcode => 'P19',
  },
  "SUFFIX" => {
    :pcode => 'P18',
  },
  # "FULLNAME" => {
    # :pcode => 'Pfullname',
  # },
  "SNAC_ID" => {
    :pcode => 'P6',
  },
  "SEX" => {
    :pcode => 'P7',
    :value_map => {
      "Male" => "Q7",
      "Female" => "Q8",
      "M" => "Q7",
      "F" => "Q8",
    }
  },
  "RACE_DESCRIPTION" => {
    :pcode => 'P13',
    :value_map => {
      "Black" => "Q9",
      "White" => "Q10",
      "W" => "Q10",
      "B" => "Q9",
      "M" => "Q11",
    }
  },
  "BIRTH_DATE" => {
    :pcode => 'P8',
  },
  "DEATH_DATE" => {
    :pcode => 'P9',
  },
  "STATE/COUNTRY_OF_BIRTH" => {
    :pcode => 'P10',
    :value_map => PLACE_MAP
  },
  "STATE/COUNTRY_OF_DEATH" => {
    :pcode => 'P11',
    :value_map => PLACE_MAP
  },
# "BIOGRAPHY" => {
  # :pcode => 'PBiography',
# },
  "CITATION" => {
    :pcode => 'P26',
  }
}