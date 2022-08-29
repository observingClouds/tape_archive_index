# Collection of reference files of data primarily archived on 📼 at DKRZ
![Check](https://github.com/observingclouds/tape_archive_index/actions/workflows/test.yml/badge.svg) [![Reference files](https://img.shields.io/badge/reference%20files-10.5281%2Fzenodo.7017188-blue)](https://doi.org/10.5281/zenodo.7017188)

Repository containing parquet-reference files to open `zarr`-files packed as `car`-collections and saved on tape.

## How to access zarr-files

To access the referenced zarr files, the following steps need to be done:

1. Get the Content-Identifier (CID) of the data of interest
    - e.g. from a source like the eurec4a-intake catalog, or
    - open archived_cids.json and copy the CID of interest
    ```python
    cid = "bafybeibk4i64g6vku2rk4ap5wrrw2b3ryrr3n274vris5dmo25vuf4k3pu"
    ```
2. Load the according reference file
    ```python
    import json
    import pandas as pd
    with open("archived_cids.json") as f:
    cids = json.load(f)
    metadata = cids[cid]
    references = pd.read_parquet(metadata["preffs"])
    ```
3. Get the referenced files that contain the actual data
    These will be in most cases `car` files
    ```python
    files_to_retrieve = pd.unique(references.path)
    files_to_retrieve = [f for f in files_to_retrieve if isinstance(f,str)]
    ```
4. Retrieve files from tape
    Note that the following steps are not possible on the login node and another partition has to be chosen with e.g. `salloc --partition=shared --mem=6GB --nodes=1 --time=02:00:00 --account <ACCOUNT>`
    ```python
    import subprocess
    target_dir = "/scratch/m/mXXXXXX/"
    path_on_tape = metadata["tape_archive_prefix"]
    for file in files_to_retrieve:
      subprocess.check_output(f"module load slk; slk retrieve {path_on_tape}{file} {target_dir}", shell=True)
    ```
    Please note that this retrieval command is not optimal as described in the [DKRZ-Resources](https://docs.dkrz.de/doc/datastorage/hsm/retrievals.html#aggregate-file-retrievals).

5. Open the reference filesystem
    ```python
    import xarray as xr
    ds = xr.open_zarr(metadata["preffs"])
    ```
