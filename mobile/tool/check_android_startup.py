"""Check cold launches on a test device; force-stops the package but never clears its data."""
import argparse
import json
import re
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--adb", default="adb")
parser.add_argument("--serial", required=True)
parser.add_argument("--cycles", type=int, default=3)
args = parser.parse_args()
package = "com.epitomehub.arrownova"
activity = package + "/com.epitomehub.arrownova.MainActivity"

def shell(*command, timeout=30):
    return subprocess.run([args.adb, "-s", args.serial, "shell", *command],
                          text=True, capture_output=True, check=True,
                          timeout=timeout).stdout

def ui():
    name = "/data/local/tmp/arrownova-startup-qa.xml"
    shell("uiautomator", "dump", "--compressed", name, timeout=15)
    return ET.fromstring(shell("cat", name))

def labels(tree):
    return " ".join(n.get("text", "") + " " + n.get("content-desc", "") for n in tree.iter())

for cycle in range(1,args.cycles+1):
    shell("am", "force-stop", package)
    t = time.monotonic()
    result = shell("am", "start", "-W", "-n", activity)
    assert "Status: ok" in result, result
    for attempt in range(3):
        tree = ui()
        if "Your quiet adventure" in labels(tree): break
        time.sleep(1)
    else: raise RuntimeError("Interactive ArrowNova home was not found")
    home_ms = round((time.monotonic()-t)*1000)
    # Actually tap the rewards card: seeing only the splash/activity is not a pass.
    for n in tree.iter():
        if "Crystal rewards" in (n.get("text","") + n.get("content-desc","")):
            x1,y1,x2,y2 = map(int,re.findall(r"\d+",n.get("bounds","")))
            shell("input","tap",str((x1+x2)//2),str((y1+y2)//2))
            break
    else: raise RuntimeError("Rewards control not found")
    time.sleep(0.6)
    assert "coins available" in labels(ui()), "Tap did not reach rewards"
    shell("input","keyevent","4")
    shell("input","keyevent","3")
    shell("am","start","-W","-n",activity)
    assert "Your quiet adventure" in labels(ui()), "Home unavailable after resume"
    print(json.dumps({"cycle":cycle, "android_start":result.strip(),
                      "home_observed_ms_including_ui_dump":home_ms,
                      "reward_tap":True, "resumed":True}), flush=True)
