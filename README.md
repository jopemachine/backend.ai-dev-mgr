# Backend.AI Developer Environment Management Tool

This script assists with the installation and management of Backend.AI.
It provides the following primary functionalities:

1. clone: Clone the repository and switch to the specified branch.
2. install: Install Backend.AI service for the specified branch.
3. run: Run a Backend.AI component. Available components: agent, manager,
   webserver, storage-proxy, all.
4. hs: Manage the halfstack environment. Available commands: up, stop, down,
   status.
5. pants: Manage the pants environment. Available commands: reset.
6. check: Verify if the system is ready for Backend.AI installation.
7. help: Display usage and command information.

The script supports the following options and arguments:
-b branch_name: Specify the branch name to use. If this option is not provided,
   the branch name will be read from the BRANCH file in the current directory.

## Repository Caching:
This script clones the Backend.AI repository into `~/.local/backend.ai/repo` and reuses this local copy as a cache to reduce network traffic and improve performance. By reusing the cached repository, subsequent operations like switching branches or pulling updates are faster and require less bandwidth.

## Resetting the Cache:
If you encounter issues or need to reset the repository cache, you can remove the cached repository by deleting the directory `~/.local/backend.ai/repo`. To do this, run the following command:
```shell
rm -rf ~/.local/backend.ai/repo
````
After deleting the cache, the script will clone a fresh copy of the repository on the next run.

## Usage examples:
`bndev.sh check`
Check if the system is ready for Backend.AI installation

`bndev.sh clone -b main`
Clone the repository and switch to the 'main' branch

`bndev.sh hs up -b main`
Start the halfstack environment using the 'main' branch

`bndev.sh install -b main`
Install Backend.AI service for the 'main' branch

`bndev.sh run all -b main`
Run all Backend.AI components for the 'main' branch

`bndev.sh hs status -b main`
Check the status of the halfstack environment for the 'main' branch

## License

Copyright (c) 2019-2024 Jeongkyu Shin <jshin@lablup.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
