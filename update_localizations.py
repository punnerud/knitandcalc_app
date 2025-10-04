#!/usr/bin/env python3
import json

# Read existing xcstrings
with open('/Users/punnerud/Downloads/KnitAndCalc/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Translation mappings (Norwegian -> English)
translations = {
    # Main menu
    "Prosjekter": "Projects",
    "Garnlager": "Yarn Stash",
    "Oppskrifter": "Recipes",
    "Garnkalkulator": "Yarn Calculator",
    "Strikkekalkulator": "Stitch Calculator",
    "Linjal": "Ruler",

    # Common
    "Avbryt": "Cancel",
    "Lagre": "Save",
    "Slett": "Delete",
    "Rediger": "Edit",
    "Ferdig": "Done",

    # Yarn stash
    "Garninformasjon": "Yarn Information",
    "Merke": "Brand",
    "Type": "Type",
    "Vekt per nøste": "Weight per skein",
    "Lengde per nøste": "Length per skein",
    "Antall nøster": "Number of skeins",
    "Farge": "Color",
    "Innfarging/Partinummer": "Dye lot/Batch number",
    "Strikkefasthet": "Gauge",
    "Notater": "Notes",
    "Skriv inn merke": "Enter brand",
    "Skriv inn type": "Enter type",
    "(Nytt merke)": "(New brand)",
    "(Ny type)": "(New type)",
    "Se detaljer": "View details",
    "Oversikt": "Summary",
    "Reservert til prosjekter": "Reserved for Projects",
    "Totalt reservert:": "Total reserved:",
    "Brukt garn": "Used Yarn",
    "Ingen brukt garn registrert": "No used yarn recorded",
    "Nytt garn": "New Yarn",
    "Rediger garn": "Edit Yarn",
    "Slett garn": "Delete Yarn",
    "Søk i garnlager": "Search yarn stash",
    "Ingen garn": "No yarn",
    "Ingen treff": "No results",
    "Trykk + for å legge til": "Tap + to add",
    "Prøv et annet søk": "Try a different search",
    "reservert": "reserved",
    "Koble fra prosjekt": "Unlink from Project",
    "Koble fra": "Unlink",
    "Koblet til prosjekter": "Linked to Projects",
    "Knytt til prosjekt": "Link to Project",
    "Legg til i prosjekt": "Add to project",

    # Project yarn
    "Velg garn": "Select Yarn",
    "Ingen garn på lager": "No yarn in stock",
    "Opprett nytt garn": "Create New Yarn",
    "Mengde": "Quantity",
    "På lager:": "In stock:",
    "Du reserverer": "You reserve",
    "Prosent av lager:": "Percent of stock:",
    "Nøster:": "Skeins:",
    "Meter:": "Meters:",
    "Gram:": "Grams:",
    "Legg til garn": "Add Yarn",
    "Rediger mengde": "Edit Quantity",

    # Projects
    "Ingen prosjekter": "No projects",
    "Nytt prosjekt": "New Project",
    "Rediger prosjekt": "Edit Project",
    "Slett prosjekt": "Delete Project",
    "Prosjekt": "Project",

    # Recipes
    "Ny oppskrift": "New Recipe",
    "Ingen oppskrifter": "No recipes",

    # Units
    "gram": "grams",
    "Gram": "Grams",
    "gram totalt": "grams total",
    "meter": "meters",
    "meter totalt": "meters total",

    # Yarn details
    "Totalt på lager": "Total in stock",
    "For morro skyld": "Just for fun",
    "Slett brukt garn": "Delete Used Yarn",

    # Messages
    "Er du sikker på at du vil slette denne brukt garn-registreringen (%@ g)?": "Are you sure you want to delete this used yarn entry (%@ g)?",
    "Er du sikker på at du vil koble fra dette garnet fra \"%@\"? Prosjektet vil også miste garnet i sin oversikt.": "Are you sure you want to unlink this yarn from \"%@\"? The project will also lose the yarn in its overview.",
    "Er du sikker på at du vil fjerne dette garnet?": "Are you sure you want to remove this yarn?",

    # Other
    "Detaljer": "Details",
    "Status": "Status",
    "Størrelse": "Size",
    "Pinnestørrelse": "Needle size",
    "Oppskrift": "Recipe",
}

# Add English translations to existing strings
for norwegian_key, english_value in translations.items():
    if norwegian_key in data["strings"]:
        if "localizations" not in data["strings"][norwegian_key]:
            data["strings"][norwegian_key]["localizations"] = {}
        if "en" not in data["strings"][norwegian_key]["localizations"]:
            data["strings"][norwegian_key]["localizations"]["en"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": english_value
                }
            }

# Add new settings strings
new_strings = {
    "menu.projects": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Prosjekter"}},
            "en": {"stringUnit": {"state": "translated", "value": "Projects"}}
        }
    },
    "menu.yarn_stash": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Garnlager"}},
            "en": {"stringUnit": {"state": "translated", "value": "Yarn Stash"}}
        }
    },
    "menu.recipes": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Oppskrifter"}},
            "en": {"stringUnit": {"state": "translated", "value": "Recipes"}}
        }
    },
    "menu.yarn_calculator": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Garnkalkulator"}},
            "en": {"stringUnit": {"state": "translated", "value": "Yarn Calculator"}}
        }
    },
    "menu.stitch_calculator": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Strikkekalkulator"}},
            "en": {"stringUnit": {"state": "translated", "value": "Stitch Calculator"}}
        }
    },
    "menu.ruler": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Linjal"}},
            "en": {"stringUnit": {"state": "translated", "value": "Ruler"}}
        }
    },
    "settings.title": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Innstillinger"}},
            "en": {"stringUnit": {"state": "translated", "value": "Settings"}}
        }
    },
    "settings.language.header": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Språk"}},
            "en": {"stringUnit": {"state": "translated", "value": "Language"}}
        }
    },
    "settings.units.header": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Enheter"}},
            "en": {"stringUnit": {"state": "translated", "value": "Units"}}
        }
    },
    "settings.units.system": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Enhetssystem"}},
            "en": {"stringUnit": {"state": "translated", "value": "Unit System"}}
        }
    },
    "settings.unit.metric": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Metrisk (m/g)"}},
            "en": {"stringUnit": {"state": "translated", "value": "Metric (m/g)"}}
        }
    },
    "settings.unit.imperial": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Imperial (yd/oz)"}},
            "en": {"stringUnit": {"state": "translated", "value": "Imperial (yd/oz)"}}
        }
    },
    "settings.info.title": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Om språkendring"}},
            "en": {"stringUnit": {"state": "translated", "value": "About Language Change"}}
        }
    },
    "settings.info.description": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Etter å ha endret språk, vennligst lukk og åpne appen igjen for at endringene skal tre i kraft."}},
            "en": {"stringUnit": {"state": "translated", "value": "After changing the language, please close and reopen the app for the changes to take effect."}}
        }
    },
    "settings.language.restart.title": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Endre språk"}},
            "en": {"stringUnit": {"state": "translated", "value": "Change Language"}}
        }
    },
    "settings.language.restart.message": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "For å endre språk må du lukke og åpne appen igjen. Vil du fortsette?"}},
            "en": {"stringUnit": {"state": "translated", "value": "To change the language, you need to close and reopen the app. Do you want to continue?"}}
        }
    },
    "settings.language.restart.cancel": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Avbryt"}},
            "en": {"stringUnit": {"state": "translated", "value": "Cancel"}}
        }
    },
    "settings.language.restart.confirm": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Endre"}},
            "en": {"stringUnit": {"state": "translated", "value": "Change"}}
        }
    },
    "Backup": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Backup"}},
            "en": {"stringUnit": {"state": "translated", "value": "Backup"}}
        }
    },
    "Eksporter backup": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Eksporter backup"}},
            "en": {"stringUnit": {"state": "translated", "value": "Export Backup"}}
        }
    },
    "Importer backup": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Importer backup"}},
            "en": {"stringUnit": {"state": "translated", "value": "Import Backup"}}
        }
    },
    "Backup eksportert": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Backup eksportert"}},
            "en": {"stringUnit": {"state": "translated", "value": "Backup Exported"}}
        }
    },
    "Backup-filen er lagret og klar til deling": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Backup-filen er lagret og klar til deling"}},
            "en": {"stringUnit": {"state": "translated", "value": "Backup file is saved and ready to share"}}
        }
    },
    "Backup importert": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Backup importert"}},
            "en": {"stringUnit": {"state": "translated", "value": "Backup Imported"}}
        }
    },
    "Data er importert og appen er oppdatert": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Data er importert og appen er oppdatert"}},
            "en": {"stringUnit": {"state": "translated", "value": "Data imported and app updated"}}
        }
    },
    "Importfeil": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Importfeil"}},
            "en": {"stringUnit": {"state": "translated", "value": "Import Error"}}
        }
    },
    "Med filer": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Med filer"}},
            "en": {"stringUnit": {"state": "translated", "value": "With files"}}
        }
    },
    "Uten filer": {
        "extractionState": "manual",
        "localizations": {
            "nb": {"stringUnit": {"state": "translated", "value": "Uten filer"}},
            "en": {"stringUnit": {"state": "translated", "value": "Without files"}}
        }
    }
}

# Add new strings to data
for key, value in new_strings.items():
    data["strings"][key] = value

# Write updated file
with open('/Users/punnerud/Downloads/KnitAndCalc/Localizable.xcstrings', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Localization file updated successfully!")