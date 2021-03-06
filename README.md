# vsts
Visual Studio Team Services lessons and reminders

# Build (Continuous Integration)
Building continuously - what a dream! Ensure correctnes of code. But is it just code?

## Execute EntityFramework Core migration
TODO

## Generate SQL script with EntityFramework Core
The procedure will be
1. Check for existance of variable in `appsettings.json` and replace it with the database connection string
2. Check the db context info so we now what we target
3. Generate SQL script in the `$(build.artifactstagingdirectory)` directory

After a successful build the script will be published along with the artificats and available for execution in a Release pipeline.

### Prerequisites
Install a file transformation tool. For example [Tokenization](https://github.com/TotalALM/VSTS-Tasks/blob/master/Tasks/Tokenization/README.md). Be sure to control the options so that placeholders and variables name will be correctly transformed.

### Variables
1. Define the variable that will be transformed in the `appsettings.json` files. For example `ConnectionStrings__Default
` with the database connection string of your choice.
2. The directory of the project that has the `Microsoft.EntityFrameworkCore.Tools.DotNet` installed. For example `EFTool = $(Build.SourcesDirectory)\src\MyApp`.

### Pipeline
Where applicable make sure that Working Directory under Advanced tab is set to `$(EFTool)` variable configured above.

**Note:** The `ef` commands outlined assume a single DbContext and that migrations are located in the `EFTool` directory. If not, make adjustements accordingly with `-p` and `-c` arguments.

| Step | Tool name | Configuration |
|------|-----------|---------------|
|   1  | Tokenization: Transform file | | 
|   2  | Command Line (Preview) | `dotnet ef dbcontext info` | 
|   3  | Command Line (Preview) | `dotnet ef migrations script -o $(build.artifactstagingdirectory)\deploy\migrations.sql` |

If the project contains multiple context then [this](https://github.com/joacar/vsts/blob/master/tools/efcore-migrations.ps1) script can be used with `$(build.artifactstagingdirectory)\deploy` as input. The script files will be created with the name of the context.

# Release
With everything nicely bundled up, we want to unzip the content and apply some scripting to get things updated on the server and our app reloaded.

## Variable group
Since we will need to interact with the database we will also need a safe place to store our variables. Create a variable group called `Database` and add four variables

| Name | Value |
|------|-------|
| DatabaseServer | my-server.database.windows.net |
| DatabaseName | my-database |
| DatabasePassword | ******** |
| DatabaseUser | my-user |

## Pipeline (agent phases)
| Step | Tool name | Configuration | Description |
|------|-----------|---------------|-------------|
|   1  | Bash (Preview) | echo $(UserPassword) | `sudo -S unzip -o WebApp.zip -d $(AppDirectory) >> /dev/null` | Unzip the artificat from Agent directory into any directory, e.g. `var/www/<my-app>/` on Ubuntu. The `>> /dev/null` redirects output to `null` pipe - that is it wont be written to std out and pollute console. |
|   2  | Bash (Preview) | `sqlcmd -S $(DatabaseServer) -d $(DatabaseName) -U $(DatabaseUser) -P $(DatabasePassword) -i $script` | The `$script` should be the path of the sql scripted generated and deployed as artificat.

**Note** Ensure that `sqlcmd` is in the path (`/usr/bin/path`) or ensure that the `sqlcmd` is added to the Agents path.

