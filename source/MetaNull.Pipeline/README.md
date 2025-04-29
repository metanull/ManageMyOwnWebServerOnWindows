# Pipeline

Pipelines permits the definion of series of steps

- A pipeline is divided in Stages
- Sages are devided in jobs
- Jobs are made of Steps
- Steps are made of indivudal commands to execute.

A pipeline shall contain at least 1 stage, containing at least 1 job, containing at least 1 step, containing at least 1 command.


Pipeline
+-- Stage
    +-- Job
        +-- Step

# GitHub Action's Way
name: $(Name)

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  $(Name):

    runs-on: $(image)

    steps:
    - uses: $(xys/abc@ver)
      with:
        $(yaml)
    - uses: $(xys/abc@ver)
    - name: $(name)
      env: $(env)
      run: $(command)

## Example: pwsdh script
- name: PowerShell script
  # You may pin to the exact commit or the version.
  # uses: Amadevus/pwsh-script@97a8b211a5922816aa8a69ced41fa32f23477186
  uses: Amadevus/pwsh-script@v2.0.3
  with:
    # PowerShell script to execute in Actions-hydrated context
    script:
      Get-Date
## Example: laravel test
name: Laravel

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  laravel-tests:

    runs-on: ubuntu-latest

    steps:
    - uses: shivammathur/setup-php@15c43e89cdef867065b0213be354c2841860869e
      with:
        php-version: '8.0'
    - uses: actions/checkout@v4
    - name: Copy .env
      run: php -r "file_exists('.env') || copy('.env.example', '.env');"
    - name: Install Dependencies
      run: composer install -q --no-ansi --no-interaction --no-scripts --no-progress --prefer-dist
    - name: Generate key
      run: php artisan key:generate
    - name: Directory Permissions
      run: chmod -R 777 storage bootstrap/cache
    - name: Create Database
      run: |
        mkdir -p database
        touch database/database.sqlite
    - name: Execute tests (Unit and Feature tests) via PHPUnit/Pest
      env:
        DB_CONNECTION: sqlite
        DB_DATABASE: database/database.sqlite
      run: php artisan test




# Nouvelle approche

## YamlDocument

- `[YamlNode]` Root
## YamlNode

||Type|Name|Node|Scalar|Comment||
|`[string]`|`Name`|_$Name_|'#text'||
|`[hashtable]`|`Property`|_$Property_|`@{'#type' = 'string|int|datetime|...'}`|(see Yaml documentation)|
|`[object[]]`|`Children`|[`YamlNode[]`]$Children|[`String[]`]$Children||
|`[string]`|`InnerText`
|`[object]`|`InnerYaml`
|`[string]`|`OuterText`
|`[object]`|`OuterYaml`