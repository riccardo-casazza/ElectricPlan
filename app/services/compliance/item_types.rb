module Compliance
  ITEM_TYPES = {
    light: "light",
    socket: "socket",
    shutter: "roller shutters",
    convector: "convector",
    cooktop: "cooktop",
    dishwasher: "dishwasher",
    washing_machine: "washing machine",
    dryer: "dryer",
    oven: "oven",
    ev_charger: "ev charger",
    water_heater: "water heater",
    freezer: "freezer"
  }.freeze

  HIGH_POWER_APPLIANCES = %w[dishwasher washing\ machine dryer oven].freeze
end
