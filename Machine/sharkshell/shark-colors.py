#!/usr/bin/env python3
import argparse
import json
import math
import re
import sys
import tempfile
from pathlib import Path

from materialyoucolor.blend import Blend
from materialyoucolor.dislike.dislike_analyzer import DislikeAnalyzer
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.hct import Hct
from materialyoucolor.quantize import ImageQuantizeCelebi
from materialyoucolor.scheme.scheme_content import SchemeContent
from materialyoucolor.scheme.scheme_expressive import SchemeExpressive
from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity
from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad
from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome
from materialyoucolor.scheme.scheme_neutral import SchemeNeutral
from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow
from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant
from materialyoucolor.utils.math_utils import difference_degrees, rotation_direction, sanitize_degrees_double, sanitize_degrees_int
from PIL import Image

PALETTE_LEVELS = [0, 5, 10, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 90, 95, 98, 99, 100]

LIGHT_GRUVBOX = [
    "FDF9F3", "FF6188", "A9DC76", "FC9867", "FFD866", "F47FD4", "78DCE8", "333034",
    "121212", "FF6188", "A9DC76", "FC9867", "FFD866", "F47FD4", "78DCE8", "333034",
]
DARK_GRUVBOX = [
    "282828", "CC241D", "98971A", "D79921", "458588", "B16286", "689D6A", "A89984",
    "928374", "FB4934", "B8BB26", "FABD2F", "83A598", "D3869B", "8EC07C", "EBDBB2",
]
LIGHT_CATPPUCCIN = [
    "dc8a78", "dd7878", "ea76cb", "8839ef", "d20f39", "e64553", "fe640b", "df8e1d",
    "40a02b", "179299", "04a5e5", "209fb5", "1e66f5", "7287fd",
]
DARK_CATPPUCCIN = [
    "f5e0dc", "f2cdcd", "f5c2e7", "cba6f7", "f38ba8", "eba0ac", "fab387", "f9e2af",
    "a6e3a1", "94e2d5", "89dceb", "74c7ec", "89b4fa", "b4befe",
]
KCOLOURS = [
    ("klink", "2980b9"),
    ("kvisited", "9b59b6"),
    ("knegative", "da4453"),
    ("kneutral", "f67400"),
    ("kpositive", "27ae60"),
]
COLOUR_NAMES = [
    "rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach", "yellow",
    "green", "teal", "sky", "sapphire", "blue", "lavender",
]


class Score:
    TARGET_CHROMA = 48.0
    WEIGHT_PROPORTION = 0.7
    WEIGHT_CHROMA_ABOVE = 0.3
    WEIGHT_CHROMA_BELOW = 0.1
    CUTOFF_CHROMA = 5.0
    CUTOFF_EXCITED_PROPORTION = 0.01

    @staticmethod
    def score(colors_to_population, filter_enabled=False):
        colors_hct = []
        hue_population = [0] * 360
        population_sum = 0

        for rgb, population in colors_to_population.items():
            hct = Hct.from_int(rgb)
            colors_hct.append(hct)
            hue = int(hct.hue)
            hue_population[hue] += population
            population_sum += population

        hue_excited_proportions = [0.0] * 360

        for hue in range(360):
            proportion = hue_population[hue] / population_sum
            for i in range(hue - 14, hue + 16):
                neighbor_hue = int(sanitize_degrees_int(i))
                hue_excited_proportions[neighbor_hue] += proportion

        scored_hct = []
        for hct in colors_hct:
            hue = int(sanitize_degrees_int(round(hct.hue)))
            proportion = hue_excited_proportions[hue]

            if filter_enabled and (hct.chroma < Score.CUTOFF_CHROMA or proportion <= Score.CUTOFF_EXCITED_PROPORTION):
                continue

            proportion_score = proportion * 100.0 * Score.WEIGHT_PROPORTION
            chroma_weight = Score.WEIGHT_CHROMA_BELOW if hct.chroma < Score.TARGET_CHROMA else Score.WEIGHT_CHROMA_ABOVE
            chroma_score = (hct.chroma - Score.TARGET_CHROMA) * chroma_weight
            score = proportion_score + chroma_score
            scored_hct.append({"hct": hct, "score": score})

        scored_hct.sort(key=lambda x: x["score"], reverse=True)

        primary = None
        for cutoff in range(20, -1, -1):
            for item in scored_hct:
                if item["hct"].chroma > cutoff and item["hct"].tone > cutoff * 3:
                    primary = item["hct"]
                    break
            if primary:
                break

        return DislikeAnalyzer.fix_if_disliked(primary) if primary else Score.score(colors_to_population, False)


def mean(values):
    return sum(values) / len(values) if values else 0


def stddev(values, mean_val):
    return math.sqrt(sum((x - mean_val) ** 2 for x in values) / len(values)) if values else 0


def calc_colourfulness(image):
    pixels = list(image.getdata())

    rg_diffs = []
    yb_diffs = []

    for r, g, b in pixels:
        rg = abs(r - g)
        yb = abs(0.5 * (r + g) - b)
        rg_diffs.append(rg)
        yb_diffs.append(yb)

    mean_rg = mean(rg_diffs)
    mean_yb = mean(yb_diffs)
    std_rg = stddev(rg_diffs, mean_rg)
    std_yb = stddev(yb_diffs, mean_yb)

    return math.sqrt(std_rg**2 + std_yb**2) + 0.3 * math.sqrt(mean_rg**2 + mean_yb**2)


def detect_variant(image):
    colourfulness = calc_colourfulness(image)

    if colourfulness < 10:
        return "neutral"
    if colourfulness < 20:
        return "content"
    return "tonalspot"


def hex_to_hct(code):
    return Hct.from_int(int("0xFF%s" % code, 16))


def grayscale(colour, light):
    colour = darken(colour, 0.35) if light else lighten(colour, 0.65)
    colour.chroma = 0
    return colour


def mix(a, b, w):
    return Hct.from_int(Blend.cam16_ucs(a.to_int(), b.to_int(), w))


def harmonize(from_hct, to_hct, tone_boost):
    difference = difference_degrees(from_hct.hue, to_hct.hue)
    rotation = min(difference * 0.8, 100)
    output_hue = sanitize_degrees_double(from_hct.hue + rotation * rotation_direction(from_hct.hue, to_hct.hue))
    return Hct.from_hct(output_hue, from_hct.chroma, from_hct.tone * (1 + tone_boost))


def lighten(colour, amount):
    diff = (100 - colour.tone) * amount
    return Hct.from_hct(colour.hue, colour.chroma + diff / 5, colour.tone + diff)


def darken(colour, amount):
    diff = colour.tone * amount
    return Hct.from_hct(colour.hue, colour.chroma - diff / 5, colour.tone - diff)


def scheme_class(variant):
    if variant == "content":
        return SchemeContent
    if variant == "expressive":
        return SchemeExpressive
    if variant == "fidelity":
        return SchemeFidelity
    if variant == "fruitsalad":
        return SchemeFruitSalad
    if variant == "monochrome":
        return SchemeMonochrome
    if variant == "neutral":
        return SchemeNeutral
    if variant == "rainbow":
        return SchemeRainbow
    if variant == "tonalspot":
        return SchemeTonalSpot
    return SchemeVibrant


def snake(name):
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", name).lower()


def argb_hex(value):
    return "%06x" % (value & 0xFFFFFF)


def build_colours(variant, primary, is_light, flavour="default"):
    cls = scheme_class(variant)
    scheme = cls(source_color_hct=primary, is_dark=not is_light, contrast_level=0.0)
    colours = {}
    for colour in MaterialDynamicColors().all_colors:
        colours[colour.name] = colour.get_hct(scheme)

    if "primaryPaletteKeyColor" in colours:
        for colour in "primary", "secondary", "tertiary", "neutral":
            colours["%s_paletteKeyColor" % colour] = colours["%sPaletteKeyColor" % colour]
        colours["neutral_variant_paletteKeyColor"] = colours["neutralVariantPaletteKeyColor"]

    gruvbox = LIGHT_GRUVBOX if is_light else DARK_GRUVBOX
    for i, code in enumerate(gruvbox):
        hct = hex_to_hct(code)
        if variant == "monochrome":
            colours["term%d" % i] = grayscale(hct, is_light)
        else:
            colours["term%d" % i] = harmonize(
                hct, colours["primary_paletteKeyColor"], (0.35 if i < 8 else 0.2) * (-1 if is_light else 1)
            )

    catppuccin = LIGHT_CATPPUCCIN if is_light else DARK_CATPPUCCIN
    for i, code in enumerate(catppuccin):
        hct = hex_to_hct(code)
        if variant == "monochrome":
            colours[COLOUR_NAMES[i]] = grayscale(hct, is_light)
        else:
            colours[COLOUR_NAMES[i]] = harmonize(hct, colours["primary_paletteKeyColor"], (-0.2 if is_light else 0.05))

    for name, code in KCOLOURS:
        hct = hex_to_hct(code)
        colours[name] = harmonize(hct, colours["primary"], 0.1)
        colours["%sSelection" % name] = harmonize(hct, colours["onPrimaryFixedVariant"], 0.1)
        if variant == "monochrome":
            colours[name] = grayscale(colours[name], is_light)
            colours["%sSelection" % name] = grayscale(colours["%sSelection" % name], is_light)

    if variant == "neutral":
        for name, hct in colours.items():
            colours[name].chroma -= 15

    if flavour == "hard":
        for colour in ("background",) + tuple(k for k in colours.keys() if k.startswith("surface")):
            colours[colour] = lighten(colours[colour], 0.4) if is_light else darken(colours[colour], 0.8)
        colours["term0"] = lighten(colours["term0"], 0.4) if is_light else darken(colours["term0"], 0.9)

    colours["text"] = colours["onBackground"]
    colours["subtext1"] = colours["onSurfaceVariant"]
    colours["subtext0"] = colours["outline"]
    colours["overlay2"] = mix(colours["surface"], colours["outline"], 0.86)
    colours["overlay1"] = mix(colours["surface"], colours["outline"], 0.71)
    colours["overlay0"] = mix(colours["surface"], colours["outline"], 0.57)
    colours["surface2"] = mix(colours["surface"], colours["outline"], 0.43)
    colours["surface1"] = mix(colours["surface"], colours["outline"], 0.29)
    colours["surface0"] = mix(colours["surface"], colours["outline"], 0.14)
    colours["base"] = colours["surface"]
    colours["mantle"] = darken(colours["surface"], 0.03)
    colours["crust"] = darken(colours["surface"], 0.05)

    if flavour == "hard":
        for colour in "base", "mantle", "crust":
            colours[colour] = lighten(colours[colour], 0.4) if is_light else darken(colours[colour], 0.9)
        for i in range(3):
            colours["overlay%d" % i] = (
                lighten(colours["overlay%d" % i], 0.4) if is_light else darken(colours["overlay%d" % i], 0.8)
            )
            colours["surface%d" % i] = (
                lighten(colours["surface%d" % i], 0.4) if is_light else darken(colours["surface%d" % i], 0.8)
            )

    hexes = {}
    for k, v in colours.items():
        hexes[k] = v if isinstance(v, str) else argb_hex(v.to_int())

    if is_light:
        hexes["success"] = "4F6354"
        hexes["onSuccess"] = "FFFFFF"
        hexes["successContainer"] = "D1E8D5"
        hexes["onSuccessContainer"] = "0C1F13"
    else:
        hexes["success"] = "B5CCBA"
        hexes["onSuccess"] = "213528"
        hexes["successContainer"] = "374B3E"
        hexes["onSuccessContainer"] = "D1E9D6"

    return hexes, scheme


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("wall")
    ap.add_argument("--mode", choices=["light", "dark"], default="dark")
    args = ap.parse_args()

    wall = Path(args.wall)
    if not wall.is_file():
        return 4

    with tempfile.TemporaryDirectory(prefix="shark-colors-") as tmp:
        tmp = Path(tmp)
        src = wall
        if wall.suffix.lower() == ".gif":
            with Image.open(wall) as img:
                try:
                    img.seek(0)
                except EOFError:
                    pass
                img = img.convert("RGB")
                src = tmp / "first_frame.png"
                img.save(src, "PNG")

        with Image.open(src) as img:
            img = img.convert("RGB")
            img.thumbnail((128, 128), Image.Resampling.NEAREST)
            thumb = tmp / "thumbnail.jpg"
            img.save(thumb, "JPEG")

        with Image.open(thumb) as ti:
            variant = detect_variant(ti)

        primary = Score.score(ImageQuantizeCelebi(str(thumb), 1, 128))
        source_code = argb_hex(primary.to_int())

        dark_hexes, dark_scheme = build_colours(variant, primary, False)
        light_hexes, _ = build_colours(variant, primary, True)

        want = args.mode
        mode_hexes = {"dark": dark_hexes, "light": light_hexes}
        colors = {
            "source_color": {
                "dark": {"color": "#" + source_code},
                "light": {"color": "#" + source_code},
                "default": {"color": "#" + source_code},
            }
        }
        for role in set(dark_hexes) | set(light_hexes):
            colors[snake(role)] = {
                "dark": {"color": "#" + dark_hexes.get(role, "000000")},
                "light": {"color": "#" + light_hexes.get(role, "ffffff")},
                "default": {"color": "#" + mode_hexes[want].get(role, "000000")},
            }

        pals = {
            "primary": dark_scheme.primary_palette,
            "secondary": dark_scheme.secondary_palette,
            "tertiary": dark_scheme.tertiary_palette,
            "neutral": dark_scheme.neutral_palette,
            "neutral_variant": dark_scheme.neutral_variant_palette,
            "error": dark_scheme.error_palette,
        }
        palettes = {}
        for name, pal in pals.items():
            palettes[name] = {str(t): {"color": "#" + argb_hex(pal.tone(t))} for t in PALETTE_LEVELS}

        sys.stdout.write(json.dumps({"colors": colors, "palettes": palettes}))
        return 0


if __name__ == "__main__":
    sys.exit(main())
