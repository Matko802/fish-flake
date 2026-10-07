import sys

qdir = sys.argv[1]
path = qdir + "/DynamicTheme.qml"
s = open(path).read()

anchor = 'import "Util.js" as Util'
assert s.count(anchor) == 1, "import anchor not found"
s = s.replace(anchor, anchor + '\nimport "WallpaperColors.js" as WallpaperColors')

n = s.count("root.themedKittyColors()")
assert n == 3, "expected 3 callers, found %d" % n
s = s.replace("root.themedKittyColors()", "root.themedKittyColorsV2()")

wrapper = '''
  function themedKittyColorsV2() {
    return WallpaperColors.buildTerminalTheme(DynColor, root.wallColors, root.roles, root.palettes, root.darkMode);
  }
'''

t = s.rstrip()
assert t.endswith("}"), "unexpected file ending"
s = t[:-1] + wrapper + "}\n"
open(path, "w").write(s)
print("patched DynamicTheme.qml")
