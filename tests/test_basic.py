import hashlib
import json

import numpy as np
import pandas as pd


def test_json_wellformed():
    with open("archived_cids.json") as f:
        json.load(f)


def test_preffs_valid_parquet():
    """Test if preffs files are available and valid parquet files"""
    with open("archived_cids.json") as f:
        r = json.load(f)

    for cid, props in r.items():
        print(cid)
        preffs = pd.read_parquet(props["preffs"])
        print(preffs.head())


def test_preffs_duplicate():
    """Test if a preffs file is given several times

    It might happen during the extention of archived_cids.json that
    due to copy-paste actions a preffs occurs under different entries
    """
    with open("archived_cids.json") as f:
        r = json.load(f)

    content_hashes = []
    for cid, props in r.items():
        preffs = pd.read_parquet(props["preffs"])
        content_test_hash = hashlib.sha1(
            np.asarray(preffs.tail().values, order="C")
        ).hexdigest()
        if content_test_hash in content_hashes:
            raise ValueError("preffs file seem to be used in several entries")
        content_hashes.append(content_test_hash)
