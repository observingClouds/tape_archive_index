# Collection of references to data archived on 📼 at DKRZ
![Check](https://github.com/observingclouds/tape_archive_index/actions/workflows/test.yml/badge.svg) [![Reference files](https://img.shields.io/badge/reference%20files-10.5281%2Fzenodo.7017188-blue)](https://doi.org/10.5281/zenodo.7017188)

Repository containing parquet-reference files to `zarr`-files packed as `car` and `tar`-collections and stored on tape.

## Application
This repository contains a look-up table of CIDs of data that is saved on the DKRZ tape archive. A user who is interested in working with the data behind a specific CID should however first try to get the content via the IPFS network or the resources given in the [EUREC4A-Intake catalog](https://github.com/eurec4a/eurec4a-intake) (currently only EUREC4A simulations are referenced here). If the dataset cannot be found, the steps described below can be followed to retrieve the data from the tape archive (access rights necessary).

This repository also offers the possibility to integrate the tape archive into the IPFS network by providing the interface between the content identifiers and the archives on tape that would need to be loaded onto an IPFS node.

## Intake catalog

### Setup
```python
slk_cache = "/scratch/m/m300408/retrieval/" # define slk cache directory
catalog = "https://raw.githubusercontent.com/observingClouds/tape_archive_index/main/catalog.yml"

import os
os.environ["SLK_CACHE"] = slk_cache 
```

### Open catalog with all available/indexed datasets
```python
from intake import open_catalog
cat=open_catalog(catalog)
sorted(list(cat))
```

```python
['EUREC4A_ICON-LES_control_DOM01_radiation_native',
 'EUREC4A_ICON-LES_control_DOM01_reff_native',
 'EUREC4A_ICON-LES_control_DOM01_surface_native',
 'EUREC4A_ICON-LES_control_DOM02_3D_native.qr+cloud_num+coords',
 'EUREC4A_ICON-LES_control_DOM02_reff_native',
 'EUREC4A_ICON-LES_control_DOM02_surface_native',
...]
```

### Select dataset of interest
```python
ds=cat["EUREC4A_ICON-LES_control_DOM01_surface_native"].to_dask()
```
The required files for any computations will be retrieved from tape when needed and cached locally.

Note: the package [`slkspec`](https://github.com/observingClouds/slkspec) needs to be installed in addition to the general intake requirements.

## Downloading the archived files manually
Another option is to download the archived files manually from tape. This is currently the preferred option if large portions of the dataset are needed, because retrievals are more sufficiently grouped together.

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
    Note that the following steps are not possible on the login node and another partition has to be chosen with e.g. `salloc --partition=interactive --mem=6GB --nodes=1 --time=02:00:00 --account <ACCOUNT>`
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
        'file001.txt|file002.txt|file100.txt'
        """
        if isinstance(files, str):
            return files
        else:
            return '|'.join(files)
    
    def search(path_on_tape, regex):
        """Search for given regex on tape and return search id
        """
        search_instruction = '{"$and":[{"path":{"$gte":"'+path_on_tape+'","$max_depth":1}},{"resources.name":{"$regex":"'+regex+'"}}]}'
        result = subprocess.check_output(f"module load slk; slk search '{search_instruction}'", shell=True).decode()
        id_idx = result.find('Search ID:')
        search_id = int(''.join(re.findall(r"[0-9]", result[id_idx:])))
        return search_id

    def ensure_preferred_sharding(dir):
        """Ensure preffered sharding of target directory is set
        """
        subprocess.call(f"lfs setstripe -E 1G -c 1 -S 1M -E 4G -c 4 -S 1M -E -1 -c 8 -S 1M {dir}", shell=True)
    
    regex = create_search_pattern(files_to_retrieve)
    search_id = search(path_on_tape,regex)
    ensure_preffered_sharding(target_dir)
    
    subprocess.check_output(f"module load slk; slk retrieve -s {search_id} {target_dir}")
    ```

5. Open the reference filesystem
    ```python
    import xarray as xr
    storage_options = {"preffs":{"prefix":"/path/to/directory/with/car/files/"}}
    ds = xr.open_zarr(f"preffs::{metadata["preffs"]}", storage_options=storage_options)
    ```

## Upload entry to zenodo
The reference files are currently stored on zenodo.

To upload or update a new file to zenodo please contact the maintainer of this repository by opening an issue or pull request. While the reference files can be uploaded to any server and any zenodo repository, we try to keep them all in one place. If you have access to the zenodo repository you find instructions on how to upload a new file to zenodo [here](https://developers.zenodo.org). Basically, you need to
1. Create an `ACCESS_TOKEN`
2. Create a new version of the zenodo dataset.
3. Grep the record number of the new version of the dataset, i.e. the last number in the url, e.g. `7485057` from https://zenodo.org/deposit/7485057
4. Find out the bucket link: e.g. `curl https://zenodo.org/api/deposit/depositions/7485057?access_token=$ACCESS_TOKEN | jq '.links.bucket'`
5. Upload the file(s), with `curl --upload-file $LOCAL_FILENAME https://zenodo.org/api/files/25794c67-d85e-45a7-b3cf-032578603fa9/$REMOTE_FILENAME?access_token=$ACCESS_TOKEN`
6. Publish the dataset and get the links to the newly added file(s). Note, these links are not the same as the one used above for the upload.
