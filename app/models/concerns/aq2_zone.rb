# AQ2 Lightning Zone Classification for France
# Based on NF C 15-100 standard (keraunic level NK > 25 days/year)
#
# AQ2 zones require surge protection (parafoudre) installation
# in certain conditions per French electrical regulations.
#
# Source: NF C 15-100 / NF C 15-100-1 (2024 revision)

module Aq2Zone
  extend ActiveSupport::Concern

  # French department codes (Carmen format) in AQ2 lightning zone
  # These departments have keraunic level NK > 25 days/year
  AQ2_DEPARTMENTS = [
    # Provence-Alpes-Côte-d'Azur (all departments)
    "04", # Alpes-de-Haute-Provence
    "05", # Hautes-Alpes
    "06", # Alpes-Maritimes
    "13", # Bouches-du-Rhône
    "83", # Var
    "84", # Vaucluse

    # Auvergne-Rhône-Alpes (all except Cantal and Allier)
    "01", # Ain
    "07", # Ardèche
    "26", # Drôme
    "38", # Isère
    "42", # Loire
    "43", # Haute-Loire
    "63", # Puy-de-Dôme
    "69", # Rhône
    "73", # Savoie
    "74", # Haute-Savoie
    # Excluded: "03" (Allier), "15" (Cantal)

    # Nouvelle-Aquitaine (specific departments)
    "33", # Gironde
    "40", # Landes
    "47", # Lot-et-Garonne

    # Occitanie (specific departments)
    "30", # Gard
    "34", # Hérault
    "48", # Lozère
    "66", # Pyrénées-Orientales

    # Bourgogne-Franche-Comté (specific departments)
    "25", # Doubs
    "39", # Jura
    "71", # Saône-et-Loire

    # Overseas territories
    "GP", # Guadeloupe
    "YT" # Mayotte
  ].freeze

  # Overseas region codes that are entirely in AQ2 zone
  AQ2_REGIONS = [
    "GF",  # Guyane française
    "MQ",  # Martinique
    "GUA", # Guadeloupe
    "MAY", # Mayotte
    "PF"  # Polynésie française (Tahiti)
  ].freeze

  class_methods do
    def aq2_departments
      AQ2_DEPARTMENTS
    end

    def aq2_regions
      AQ2_REGIONS
    end
  end

  # Check if dwelling is in AQ2 lightning zone
  def in_aq2_zone?
    return false unless country_code == "FR"

    # Check if entire region is AQ2
    return true if AQ2_REGIONS.include?(region_code)

    # Check if department is AQ2
    AQ2_DEPARTMENTS.include?(department_code)
  end

  # Check if dwelling is outside AQ2 zone (but still in France)
  def outside_aq2_zone?
    return false unless country_code == "FR"
    !in_aq2_zone?
  end
end
