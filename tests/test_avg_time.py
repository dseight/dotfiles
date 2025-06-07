import unittest
from datetime import timedelta

import util

util.import_module(".scripts/avg-time", "avgtime")
from avgtime import parse_time


class TestTimeParsing(unittest.TestCase):
    def test_posix(self):
        # posix format: 0.01
        self.assertEqual(parse_time("60.00"), timedelta(minutes=1))
        self.assertEqual(parse_time("1.00"), timedelta(seconds=1))
        self.assertEqual(parse_time("0.01"), timedelta(milliseconds=10))

    def test_bash(self):
        # bash format: 0m0.010s
        self.assertEqual(parse_time("1m0.000s"), timedelta(minutes=1))
        self.assertEqual(parse_time("0m1.000s"), timedelta(seconds=1))
        self.assertEqual(parse_time("0m0.010s"), timedelta(milliseconds=10))
        self.assertEqual(parse_time("0m0.001s"), timedelta(milliseconds=1))

    def test_busybox(self):
        # busybox format: 0m 0.01s
        self.assertEqual(parse_time("1m 0.00s"), timedelta(minutes=1))
        self.assertEqual(parse_time("0m 1.00s"), timedelta(seconds=1))
        self.assertEqual(parse_time("0m 0.01s"), timedelta(milliseconds=10))
