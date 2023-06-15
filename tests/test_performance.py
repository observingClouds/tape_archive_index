import intake
import numpy as np
import pandas as pd
import pytest

cat = intake.open_catalog("catalog.yml")


def remove_metadata(df):
    df["tmp"] = df.index.str.findall(".z")
    df_chunks_only = df[df["tmp"].apply(lambda l: l == list())].copy()
    del df_chunks_only["tmp"]
    return df_chunks_only


def add_var_column(df):
    df["tmp"] = df.index.str.split("/")
    df["var"] = df["tmp"].apply(lambda f: f[0])
    del df["tmp"]
    return df


def preffs_fn(cat_entry):
    fn = cat_entry.describe()["args"]["urlpath"].replace("preffs::", "", 1)
    return fn


@pytest.mark.parametrize("entry", cat)
def test_consequtive_files(entry, cat=cat):
    """
    Test whether consequtive keys (chunks) are also saved to
    consequtive files.

    Note: this assumes that path names and keys can be
    sorted with the python internal sort alogirthm.
    """
    cat_entry = cat[entry]
    preffs_file = preffs_fn(cat_entry)
    df = pd.read_parquet(preffs_file)

    df_data = remove_metadata(df).copy()
    df_data = add_var_column(df_data).copy()

    entry_success = True
    unoptimized_vars = []
    for var, var_grp in df_data.groupby("var"):
        paths_idx_sorted = var_grp.sort_index(kind="stable").index
        paths_path_sorted = var_grp.sort_values("path", kind="stable").index
        success = bool(np.all(paths_path_sorted == paths_idx_sorted))
        if success is False:
            entry_success = False
            unoptimized_vars.append(var)
    assert (
        entry_success
    ), f"Dataset not optimized for subset retrievals ({unoptimized_vars})"
