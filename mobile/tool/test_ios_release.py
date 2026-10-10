import json
import plistlib
import tempfile
import unittest
from pathlib import Path
from ios_release import configure, validate_ads, verify_archive, TEST_APP


class ReleaseConfigurationTest(unittest.TestCase):
    def ids(self):
        return {"ADMOB_APP_ID": "ca-app-pub-1234567890123456~1234567890",
                "IOS_BANNER_ID": "ca-app-pub-1234567890123456/1234567891",
                "IOS_INTERSTITIAL_ID": "ca-app-pub-1234567890123456/1234567892",
                "IOS_REWARDED_ID": "ca-app-pub-1234567890123456/1234567893"}

    def test_live_ids(self):
        self.assertEqual(validate_ads(self.ids()), self.ids())
        for value in ["", "placeholder", TEST_APP, "ca-app-pub-1234567890123456/1234567890\nOTHER=1"]:
            with self.assertRaises(ValueError):
                validate_ads({**self.ids(), "ADMOB_APP_ID": value})

    def test_reject_android_test_duplicate_and_mixed_publisher(self):
        for value in ["ca-app-pub-9061518700917881/4239172993",
                      "ca-app-pub-3940256099942544/2934735716",
                      self.ids()["IOS_INTERSTITIAL_ID"],
                      "ca-app-pub-9999999999999999/1234567891"]:
            with self.assertRaises(ValueError):
                validate_ads({**self.ids(), "IOS_BANNER_ID": value})

    def test_test_mode_clears_stale_live_settings(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "ios").mkdir()
            (root / "ios/ads.ios.local.json").write_text(json.dumps(self.ids()))
            configure("store", "ABCDE12345", root)
            configure("test", "ABCDE12345", root)
            self.assertIn(TEST_APP, (root / "ios/Flutter/Ads.local.xcconfig").read_text())
            self.assertEqual(json.loads((root / ".build-tmp/ios/defines.json").read_text()), {"LIVE_ADS": False})
            with (root / ".build-tmp/ios/ExportOptions.plist").open("rb") as source:
                export = plistlib.load(source)
            self.assertFalse(export["manageAppVersionAndBuildNumber"])
            self.assertEqual(export["teamID"], "ABCDE12345")

    def test_missing_live_config_and_invalid_team_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                configure("store", "ABCDE12345", Path(directory))
            with self.assertRaises(ValueError):
                configure("test", "not-a-team", Path(directory))

    def test_archive_rejects_mismatched_id(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory)
            app = archive / "Products/Applications/Runner.app"
            app.mkdir(parents=True)
            with (app / "Info.plist").open("wb") as output:
                plistlib.dump({"CFBundleIdentifier": "com.epitomehub.arrownova", "GADApplicationIdentifier": "WRONG"}, output)
            with self.assertRaises(ValueError):
                verify_archive(archive, "test")


if __name__ == "__main__":
    unittest.main()
