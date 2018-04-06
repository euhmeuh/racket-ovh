# racket-ovh
Unofficial Racket wrapper for OVH API

## Build

`raco exe ovh-api.rkt`  
  
Then you're free to add the produced `ovh-api` executable to your PATH.  

## Configure

Set the environment variables `OVH_API_KEY`, `OVH_SECRET_KEY` and `OVH_CONSUMER_KEY`.  
See [the OVH documentation](https://api.ovh.com/g934.first_step_with_api) to get them.

## Usage

`ovh-api GET /me`  
`ovh-api --v7 --expand GET /hosting/privateDatabase`  
`ovh-api --v7 -e -a \$fields displayName GET /hosting/privateDatabase`  
  
`ovh-api --help` for available commands.

## Disclaimer

This piece of software is in NO WAY related to OVH SAS nor any of its activities.  
It is NOT undorsed nor developed by OVH SAS.  
  
It is provided as a free and open source software under the terms of the GNU Lesser General Public License v3.  
  
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.  
  
You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.  
