# Testing
## Checking checksums
To check whether to local and remote checksums agree, it is advisable to calculate the local checksums first and save them in a temporary file.
This allows to quickly run the check at a later time again as the tape archive might not have all checksums available within a few days.

### Calculating local checksums
```
ls -1 *.tar > tar_list
cat tar_list | xargs -n16 -P16 sha512sum
```

### Comparison with remote checksums
```python
import tqdm; import subprocess; import pandas as pd
l=pd.read_table("checksums_local", delim_whitespace=True, names=['sha512','file'])
l=l.set_index("file")
command = "module load slk; slk_helpers checksum /arch/mh0010/m300408/experiments/EUREC4A/highCCN/output/DOM02/3D/{file}"
for file, sha in tqdm.tqdm(l.iterrows()):
    local_hash = str(sha.values[0])
    try:
        remote_hash = subprocess.check_output(command.format(file=file),shell=True)
        remote_hash = remote_hash.decode()[int(remote_hash.decode().find("sha512:")+8):int(-1)]
    except subprocess.CalledProcessError:
        print(f"Probably no checksum for {file} yet on tape")
        continue
    if local_hash != remote_hash: print("file differs")
```
If checksums disagree or are not yet present on the archive a message is printed.
