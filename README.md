# Collection of references to data archived on 📼 at DKRZ
![Check](https://github.com/observingclouds/tape_archive_index/actions/workflows/test.yml/badge.svg) [![Reference files](https://img.shields.io/badge/reference%20files-10.5281%2Fzenodo.7017188-blue)](https://doi.org/10.5281/zenodo.7017188)

Repository containing parquet-reference files to `zarr`-files packed as `car`-collections and stored on tape.

## Application
This repository contains a look-up table of CIDs of data that is saved on the DKRZ tape archive. A user who is interested in working with the data behind a specific CID should however first try to get the content via the IPFS network or the resources given in the [EUREC4A-Intake catalog](https://github.com/eurec4a/eurec4a-intake) (currently only EUREC4A simulations are referenced here). If the dataset cannot be found, the steps described below can be followed to retrieve the data from the tape archive (access rights necessary).

This repository also offers the possibility to integrate the tape archive into the IPFS network by providing the interface between the content identifiers and the archives on tape that would need to be loaded onto an IPFS node.

## How to access files
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
3. Get a list of referenced files that contain the actual data
    These will be in most cases `car` files
    ```python
    files_to_retrieve = pd.unique(references.path)
    files_to_retrieve = [f for f in files_to_retrieve if isinstance(f,str)]
    ```
4. Retrieve files from tape
    Note that the following steps are not possible on the login node and another partition has to be chosen with e.g. `salloc --partition=shared --mem=6GB --nodes=1 --time=02:00:00 --account <ACCOUNT>`
    ```python
    import re
    import subprocess
    import numpy as np
    
    target_dir = "/scratch/m/mXXXXXX/"
    path_on_tape = metadata["tape_archive_prefix"]

    def create_search_pattern(files):
    """Create simple regexp from given list of files

    >>> files = ['file001.txt', 'file002.txt', 'file100.txt']
    >>> create_search_pattern(files)
    'file[0-9]0[0-9].txt'
    """
    if len(files) == 1 or isinstance(files, str):
        return files
    char_array = np.array([list(file) for file in files])
    check = lambda x: len(set(x)) == 1
    mask_differences = np.apply_along_axis(check, 0, char_array)
    idx_differences = list(np.hstack(np.argwhere(mask_differences == False)))
    pattern = files[0]
    regex = '[0-9]'
    parts = [pattern[i:j] for i,j in zip([0]+idx_differences, idx_differences[0:]+[None])]
    for i in range(1,len(parts)):
        parts[i] = regex+parts[i][1:]
    return ''.join(parts)
    
    def search(path_on_tape, regex):
    """Search for given regex on tape and return search id
    """
    search_instruction = '{"$and": [{"path": {"$gte": "'+path_on_tape+'", "$max_depth": 1}}, {"resources.name": {"$regex": "'+regex+'"}}]}'
    result = subprocess.check_output(f"module load slk; slk_helpers search_limited '{search_instruction}'", shell=True).decode()
    id_idx = result.find('Search ID:')
    search_id = int(''.join(re.findall(r"[0-9]", result[id_idx:])))
    return search_id
    
    regex = create_search_pattern(files_to_retrieve)
    search_instruction = '{"$and": [{"path": {"$gte": "'+path_on_tape+'", "$max_depth": 1}}, {"resources.name": {"$regex": "'+regex+'"}}]}'
    result = subprocess.check_output(f"module load slk; slk_helpers search_limited '{search_instruction}'", shell=True)
    search_id = search(path_on_tape,regex)
    
    subprocess.check_output(f"module load slk; slk retrieve {search_id} {target_dir}")
    ```

5. Open the reference filesystem
    ```python
    import xarray as xr
    ds = xr.open_zarr(f"preffs::{metadata["preffs"]}")
    ```
